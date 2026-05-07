/**
 * Synthesis Agent — Tier 2 of the three-tier enforcement model.
 *
 * Runs AFTER all domain agents complete. Acts as the Principal EA referee:
 *  - Rationalises cross-domain evidence (can lower domain scores, not raise Security/DR)
 *  - Applies the ADR architectural-choice gate (removes documentation-only ADRs)
 *  - Writes an executive rationale paragraph
 *  - Issues a final recommended decision that honours Tier-1 floors
 */

import { callLLM, parseJsonFromLLM } from '../utils/llm.ts'

export interface DomainScoreMap {
  [domain: string]: number
}

export interface ScoreCorrection {
  domain:         string
  original_score: number
  corrected_score: number
  reason:         string
}

export interface SynthesisInput {
  reviewId:          string
  solutionName:      string
  domainScores:      DomainScoreMap
  allFindings:       any[]
  allBlockers:       any[]
  allAdrs:           any[]
  allActions:        any[]
  aggregateScore:    number
  model:             string
}

export interface SynthesisResult {
  finalDomainScores:   DomainScoreMap
  scoreCorrections:    ScoreCorrection[]
  retainBlockerIds:    string[] | null  // canonical blocker IDs after cross-domain dedup; null = keep all
  filteredAdrIds:      string[]         // ADR IDs retained after architectural-choice gate
  removedAdrIds:       string[]         // ADR IDs removed (documentation-only — actions used instead)
  executiveRationale:  string
  finalDecision:       string
  tokensUsed:          number
}

// ── System prompt ─────────────────────────────────────────────────────────────

const SYNTHESIS_SYSTEM_PROMPT = `You are a senior Principal Enterprise Architect with 20 years of experience
chairing ARB panels. You are writing the final synthesis of an AI-assisted architectural review. All domain
agents have completed their assessments and you are now producing the executive view.

ARB SCOPE REMINDER: This review covers architectural design completeness only — not operational readiness,
test results, or deployed-state evidence. Your synthesis must stay within this scope.

YOUR FIVE RESPONSIBILITIES:

1. SCORE RATIONALISATION — review domain scores for cross-cutting consistency:
   • You MAY LOWER a domain score if cross-domain evidence reveals a compounding risk not visible in
     isolation (e.g. Security RED but DR domain GREEN — DR should reflect the security gap).
   • You MAY NEVER RAISE Security or DR/HA domain scores above RED (rag_score 2) unless the domain
     agent's own findings contain positive architectural evidence supporting a higher score.
   • For all other domains you may raise or lower scores by at most 1 point when cross-domain evidence
     clearly supports it. Document every correction with a specific reason.
   • Output scoreCorrections[] for every change. If no corrections needed, output an empty array.

2. BLOCKER CONSOLIDATION — deduplicate cross-domain blockers:
   Multiple domain agents independently assess overlapping concerns — it is expected that the same
   architectural gap (e.g. missing RBAC design) may appear as a blocker in both the infrastructure
   and NFR domains. Your job is to consolidate these into one canonical blocker per distinct issue.
   
   EXAMPLES OF DUPLICATE BLOCKERS TO CONSOLIDATE:
   • Infrastructure: "Missing Authentication & Authorization (AUTHN_AUTHZ) design" 
     + NFR: "Missing RBAC/IAM scope for EDMS service accounts" → SAME ISSUE → keep one
   • Infrastructure: "Incomplete Key Vault and Secrets Management (KEY_VAULT_SECRETS) design"
     + NFR: "Missing Key Vault and Secrets Management design for EDMS" → SAME ISSUE → keep one
   • Infrastructure: "Absence of detailed PKI and Encryption (PKI_ENCRYPTION) design"
     + NFR: "Absent encryption-at-rest and in-transit design for EDMS" → SAME ISSUE → keep one
   
   CONSOLIDATION RULES:
   • Compare all blockers by subject matter (title + description), not by ID.
   • Look for semantic similarity: same control area (auth, encryption, secrets, etc.) even if phrased differently.
   • Where two or more blockers describe the same underlying gap, retain ONE — prefer the one with
     the most specific description or from the domain most architecturally responsible for it.
   • Output retainBlockerIds[] — the exact IDs of the blockers to keep after consolidation.
     All blocker IDs not in this list are treated as redundant duplicates and discarded.
   • If all blockers are distinct issues, retainBlockerIds must include every blocker ID.
   • Never drop a blocker to soften the outcome — only consolidate genuine cross-domain duplicates.

3. ADR GATE — apply the architectural-choice test to every ADR in the input:
   RETAIN an ADR if it records: a deliberate design decision between viable options, a technology
   deviation from EA standards, or a formal exception (WAIVER) for a genuine design risk.
   REMOVE an ADR if it was generated merely because documentation or a plan is absent — those should
   be actions, not ADRs. A missing VAPT plan → action. A decision to skip encryption at rest → ADR.
   Output filteredAdrIds (retained) and removedAdrIds (removed).

4. EXECUTIVE RATIONALE — write 4–6 sentences as a senior EA would speak at an ARB panel:
   Write in first-person plural ("The panel notes…", "We find…", "The architecture demonstrates…").
   Sound like a considered human judgement, not a system-generated checklist.
   • Open with what the solution gets right — acknowledge genuine strengths before gaps.
   • Describe the critical gaps in concrete terms — name the specific controls or design elements
     missing, not just the domain category. Reference the solution by name.
   • If there are blockers, explain WHY they prevent approval — the business or security consequence,
     not just that a standard is violated.
   • Close with a clear path forward: what the SA team must produce, and at what level of completeness,
     before the panel can reconsider.
   Avoid: bullet-point-in-prose style, hedging language ("it appears", "may be"), repeating the same
   gap twice with different words, and generic phrases like "the solution lacks documentation".

5. FINAL DECISION — one of: approve | approve_with_conditions | defer | reject
   Apply these Tier-1 floors using the RETAINED blockers after consolidation:
   • Any Security or DR/HA blocker (is_security_or_dr = true) at rag_score ≤ 1 → reject
   • Any Security or DR/HA blocker at rag_score 2 → defer
   • Non-security/DR blockers or score ≤ 3 → approve_with_conditions
   • Score ≥ 4 and no blockers → approve

Respond ONLY with a valid JSON object. No preamble, no markdown outside the JSON.`

// ── User prompt builder ───────────────────────────────────────────────────────

function buildSynthesisPrompt(input: SynthesisInput): string {
  const domainScoreLines = Object.entries(input.domainScores)
    .map(([d, s]) => `  ${d.padEnd(20)} rag_score=${s}`)
    .join('\n')

  const blockerLines = input.allBlockers.map(b =>
    `  id=${b.id} [${b.is_security_or_dr ? 'SEC/DR' : 'OTHER '}] ${b.domain} — ${b.title} (is_security_or_dr=${b.is_security_or_dr})`
  ).join('\n') || '  (none)'

  const adrLines = input.allAdrs.map(a =>
    `  ${a.id} | ${a.adr_type} | ${a.title}`
  ).join('\n') || '  (none)'

  const findingSummary = input.allFindings
    .filter(f => (f.rag_score ?? 5) <= 3)
    .map(f => `  ${f.id} rag=${f.rag_score} [${f.check_category}] ${f.title}`)
    .slice(0, 30)
    .join('\n') || '  (no RED/AMBER findings)'

  return `== SYNTHESIS INPUT ==
review_id:      ${input.reviewId}
solution_name:  ${input.solutionName}
aggregate_score: ${input.aggregateScore}

== DOMAIN SCORES FROM DOMAIN AGENTS ==
${domainScoreLines}

== BLOCKERS ==
${blockerLines}

== ADRs TO GATE ==
${adrLines}

== RED/AMBER FINDINGS (up to 30) ==
${findingSummary}

== OUTPUT SCHEMA ==
{
  "scoreCorrections": [
    { "domain": "security", "original_score": 2, "corrected_score": 2, "reason": "No change — consistent with findings" }
  ],
  "retainBlockerIds": ["INF-BLK-01", "NFR-BLK-05"],
  "filteredAdrIds": ["ADR-SEC-01", "ADR-APP-02"],
  "removedAdrIds":  ["ADR-INF-03"],
  "executiveRationale": "4-6 sentence paragraph written in EA voice for the ARB panel",
  "finalDecision": "approve | approve_with_conditions | defer | reject"
}`
}

// ── Safe fallback ─────────────────────────────────────────────────────────────

function buildFallbackResult(input: SynthesisInput, reason: string): SynthesisResult {
  const hasSecDrBlocker = input.allBlockers.some(b => b.is_security_or_dr)
  const hasBlockers     = input.allBlockers.length > 0

  let finalDecision: string
  if (input.aggregateScore >= 4 && !hasBlockers) {
    finalDecision = 'approve'
  } else if (input.aggregateScore <= 1 && hasSecDrBlocker) {
    finalDecision = 'reject'
  } else if (hasSecDrBlocker) {
    finalDecision = 'defer'
  } else if (hasBlockers || input.aggregateScore <= 3) {
    finalDecision = 'approve_with_conditions'
  } else {
    finalDecision = 'approve'
  }

  return {
    finalDomainScores:  { ...input.domainScores },
    scoreCorrections:   [],
    retainBlockerIds:   null,  // null = keep all (fallback doesn't deduplicate)
    filteredAdrIds:     input.allAdrs.map(a => a.id).filter(Boolean),
    removedAdrIds:      [],
    executiveRationale: `Synthesis step unavailable (${reason}). Domain agent scores are used as-is. Decision is determined by Tier-1 gate logic only.`,
    finalDecision,
    tokensUsed:         0,
  }
}

// ── Main entry point ──────────────────────────────────────────────────────────

export async function runSynthesis(input: SynthesisInput): Promise<SynthesisResult> {
  let raw: string
  let tokensUsed = 0

  try {
    const llmResult = await callLLM({
      systemPrompt: SYNTHESIS_SYSTEM_PROMPT,
      userPrompt:   buildSynthesisPrompt(input),
      model:        input.model,
    })
    raw        = llmResult.content
    tokensUsed = llmResult.tokensUsed
  } catch (err) {
    console.error('[SYNTHESIS] LLM call failed:', err)
    return buildFallbackResult(input, `LLM error: ${err}`)
  }

  let parsed: any
  try {
    parsed = parseJsonFromLLM(raw)
  } catch (err) {
    console.error('[SYNTHESIS] JSON parse failed:', err)
    return buildFallbackResult(input, 'parse failure')
  }

  // Apply score corrections to produce finalDomainScores
  const finalDomainScores: DomainScoreMap = { ...input.domainScores }
  const corrections: ScoreCorrection[] = []

  for (const c of (parsed.scoreCorrections ?? [])) {
    const domain  = c.domain as string
    const origInInput = input.domainScores[domain] ?? c.original_score
    const corrected   = Math.max(1, Math.min(5, Number(c.corrected_score)))

    // Tier-1 floor: never raise Security or DR/HA above their agent score via synthesis
    const isSecOrDr = domain === 'security' || domain === 'infrastructure'
    if (isSecOrDr && corrected > origInInput) {
      console.warn(`[SYNTHESIS] Blocked attempt to raise ${domain} score from ${origInInput} to ${corrected}`)
      continue
    }

    if (corrected !== origInInput) {
      finalDomainScores[domain] = corrected
      corrections.push({
        domain,
        original_score:  origInInput,
        corrected_score: corrected,
        reason:          c.reason ?? '',
      })
    }
  }

  // Blocker consolidation — filter to canonical set if synthesis provided retainBlockerIds
  const allBlockerIds = new Set(input.allBlockers.map(b => b.id).filter(Boolean))
  const rawRetain: string[] | undefined = parsed.retainBlockerIds
  let retainBlockerIds: string[] | null = null
  if (Array.isArray(rawRetain) && rawRetain.length > 0) {
    const retainSet = rawRetain.filter(id => allBlockerIds.has(id))
    retainBlockerIds = retainSet.length > 0 ? retainSet : null
  }

  // Derive final decision honouring Tier-1 floors (use retained blockers after consolidation)
  const allAdrIds      = input.allAdrs.map(a => a.id).filter(Boolean)
  const filteredAdrIds = (parsed.filteredAdrIds ?? allAdrIds).filter((id: string) => allAdrIds.includes(id))
  const removedAdrIds  = (parsed.removedAdrIds  ?? []).filter((id: string) => allAdrIds.includes(id))

  const retainSet        = retainBlockerIds ? new Set(retainBlockerIds) : null
  const retainedBlockers = retainSet
    ? input.allBlockers.filter(b => retainSet.has(b.id))
    : input.allBlockers

  const finalScores    = Object.values(finalDomainScores)
  const finalAggregate = finalScores.length ? Math.min(...finalScores) : input.aggregateScore
  const hasSecDrBlocker = retainedBlockers.some(b => b.is_security_or_dr)
  const hasBlockers     = retainedBlockers.length > 0

  let finalDecision: string
  if (finalAggregate >= 4 && !hasBlockers) {
    finalDecision = 'approve'
  } else if (finalAggregate <= 1 && hasSecDrBlocker) {
    finalDecision = 'reject'
  } else if (hasSecDrBlocker) {
    finalDecision = 'defer'
  } else if (hasBlockers || finalAggregate <= 3) {
    finalDecision = 'approve_with_conditions'
  } else {
    finalDecision = 'approve'
  }

  return {
    finalDomainScores,
    scoreCorrections:   corrections,
    retainBlockerIds,
    filteredAdrIds,
    removedAdrIds,
    executiveRationale: parsed.executiveRationale ?? '',
    finalDecision,
    tokensUsed,
  }
}
