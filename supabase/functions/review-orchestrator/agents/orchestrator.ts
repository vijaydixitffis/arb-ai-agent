import { DomainResult, Finding } from './domain-agent.ts'
import { callLLM, parseJsonFromLLM } from '../utils/llm.ts'
import {
  buildDomainContext,
  buildSolutionContextBlock,
  buildArtefactBlock,
  buildNfrCriteriaBlock,
  getKnowledgeBaseContent,
  getKbCategoriesForAgent,
  getRegistryForAgent,
  extractCheckCategories,
} from './context-builder.ts'
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ── Domain metadata ───────────────────────────────────────────────────────────

const DOMAIN_LABEL: Record<string, string> = {
  general:      'General Architecture',
  business:     'Business Domain',
  application:  'Application Domain',
  software:     'Software Architecture',
  integration:  'Integration Domain',
  api:          'API Design & Standards',
  security:     'Security Domain',
  data:         'Data Domain',
  infra:        'Infrastructure & Platform',
  devsecops:    'DevSecOps Domain',
  engg_quality: 'Engineering Excellence',
  nfr:          'Non-Functional Requirements',
}

const DOMAIN_CODE: Record<string, string> = {
  general:      'GEN',
  business:     'BUS',
  application:  'APP',
  software:     'SFT',
  integration:  'INT',
  api:          'API',
  security:     'SEC',
  data:         'DAT',
  infra:        'INF',
  devsecops:    'DSO',
  engg_quality: 'ENG',
  nfr:          'NFR',
}

// ── Interfaces ────────────────────────────────────────────────────────────────

export interface ReviewInput {
  review: any
  reportJson: any
  artifactText: string
  supabase: SupabaseClient
  scopeTags: string[]
}

export interface DomainAdr {
  id: string
  type: 'DECISION' | 'WAIVER'
  decision: string
  rationale: string
  context?: string
  owner: string
  target_date: string | null
  waiver_expiry_date?: string | null
}

export interface DomainAction {
  id: string
  finding_ref: string
  action: string
  owner_role: string
  due_days: number
  priority: 'HIGH' | 'MEDIUM' | 'LOW'
}

export interface ReviewResult {
  decision: 'approve' | 'approve_with_conditions' | 'defer' | 'reject'
  aggregateScore: number
  domainScores: Record<string, number>
  findings: Finding[]
  adrs: DomainAdr[]
  actions: DomainAction[]
  fullReport: any
  tokensUsed: number
  rawResponse: string
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// Map LLM rag_score (1–5) to the DB findings.severity constraint values.
function ragScoreToSeverity(ragScore: number): 'critical' | 'major' | 'minor' {
  if (ragScore <= 1) return 'critical'
  if (ragScore <= 2) return 'major'
  return 'minor'
}

// ── Orchestrator ──────────────────────────────────────────────────────────────

export class OrchestratorAgent {
  async validateReview(input: ReviewInput): Promise<ReviewResult> {
    const { review, reportJson, artifactText, supabase, scopeTags } = input

    console.log(`Orchestrator: Starting validation for review ${review.id}`)
    console.log(`Scope tags: ${scopeTags.join(', ')}`)

    const agentDomainMap: Record<string, string[]> = {
      general:        ['general'],
      business:       ['business'],
      application:    ['application', 'software'],
      integration:    ['integration', 'api'],
      data:           ['data'],
      infrastructure: ['infra', 'security'],
      devsecops:      ['devsecops', 'engg_quality'],
      nfr:            ['nfr'],
    }

    const uniqueDomains = [...new Set(
      scopeTags.flatMap(tag => agentDomainMap[tag] ?? [tag])
    )]
    console.log(`Processing domains: ${uniqueDomains.join(', ')}`)

    const domainResults:    DomainResult[] = []
    const allFindings:      Finding[]      = []
    const allAdrs:          DomainAdr[]    = []
    const allActions:       DomainAction[] = []
    const allRecommendations: any[]        = []
    let totalTokensUsed = 0

    for (const agentDomain of uniqueDomains) {
      console.log(`\n=== Processing domain: ${agentDomain} ===`)

      const domainCode  = DOMAIN_CODE[agentDomain]  ?? agentDomain.toUpperCase()
      const domainLabel = DOMAIN_LABEL[agentDomain] ?? agentDomain

      // 1. Checklist + evidence enriched by question_registry
      const checklistContext = await buildDomainContext(supabase, reportJson, agentDomain)

      // 2. Check categories for mandatory coverage instruction
      const registry        = await getRegistryForAgent(supabase, agentDomain)
      const checkCategories = extractCheckCategories(registry)

      // 3. Artefact block — uses artefact_uploads; falls back to raw extracted text
      const artefactBlock   = buildArtefactBlock(reportJson, agentDomain)
      const artefactContext = artefactBlock.includes('none available') && artifactText
        ? `== PARSED ARTEFACT (raw extraction) ==\n${artifactText.slice(0, 8000)}`
        : artefactBlock

      // 4. NFR quantitative criteria (nfr domain only)
      const nfrContext = agentDomain === 'nfr' ? buildNfrCriteriaBlock(reportJson) : ''

      // 5. Knowledge-base RAG context (in user prompt, per spec)
      const kbCategories = getKbCategoriesForAgent(agentDomain)
      const kbContext    = await getKnowledgeBaseContent(supabase, kbCategories)

      // 6. Build prompts per spec structure
      const systemPrompt = this.buildDomainSystemPrompt(domainLabel)
      const userPrompt   = this.buildDomainUserPrompt({
        sessionId: review.id,
        reportJson,
        domainCode,
        kbContext,
        checklistContext,
        artefactContext,
        nfrContext,
        checkCategories,
      })

      console.log(`Calling LLM for domain: ${agentDomain} (${domainCode})`)
      const llmResponse = await callLLM({
        systemPrompt,
        userPrompt,
        model: review.llm_model || Deno.env.get('GEMINI_MODEL') || 'gemini-2.5-flash-lite',
      })
      totalTokensUsed += llmResponse.tokensUsed

      // 7. Parse DomainReviewPayload (handles markdown fences)
      let domainReport: any
      try {
        domainReport = parseJsonFromLLM(llmResponse.content)
      } catch (parseErr) {
        console.error(`JSON parse failed for domain ${agentDomain}:`, parseErr)
        console.error('Raw LLM content (first 500 chars):', llmResponse.content.slice(0, 500))
        domainReport = { summary: { rag_score: 3 }, findings: [], blockers: [], recommendations: [], actions: [], adrs: [] }
      }

      // 8. Domain score — LLM-authoritative via summary.rag_score (spec rule 7)
      const domainScore: number = (() => {
        const raw = Number(domainReport.summary?.rag_score)
        return raw >= 1 && raw <= 5 ? Math.round(raw) : 3
      })()

      // 9. Findings (from findings[] array; rag_score drives DB severity)
      const domainFindings: Finding[] = (domainReport.findings ?? []).map((f: any) => ({
        domain:         agentDomain,
        principle_id:   f.principle_id  ?? '',
        severity:       ragScoreToSeverity(Number(f.rag_score) || 3),
        finding:        f.finding       ?? '',
        recommendation: '',                     // recommendations live in their own array
        check_category: f.check_category ?? '',
      }))

      // 10. Blockers merged into findings array as severity='critical'
      const blockerFindings: Finding[] = (domainReport.blockers ?? []).map((b: any) => ({
        domain:         agentDomain,
        principle_id:   '',
        severity:       'critical' as const,
        finding:        b.description       ?? '',
        recommendation: b.resolution_required ?? '',
        check_category: 'BLOCKER',
      }))

      allFindings.push(...domainFindings, ...blockerFindings)

      // 11. Recommendations (stored in fullReport only — no dedicated DB table)
      allRecommendations.push(
        ...(domainReport.recommendations ?? []).map((r: any) => ({
          ...r,
          domain: agentDomain,
        }))
      )

      // 12. Actions
      const domainActions: DomainAction[] = (domainReport.actions ?? []).map((a: any) => ({
        id:          a.id         ?? `${domainCode}-ACT-${Date.now()}`,
        finding_ref: a.finding_ref ?? '',
        action:      a.action      ?? '',
        owner_role:  a.owner_role  ?? 'solution_architect',
        due_days:    Number(a.due_days) || 30,
        priority:    a.priority    ?? 'MEDIUM',
      }))
      allActions.push(...domainActions)

      // 13. ADRs
      const domainAdrs: DomainAdr[] = (domainReport.adrs ?? []).map((d: any) => ({
        id:                 d.id                ?? `ADR-${domainCode}-${Date.now()}`,
        type:               d.type              ?? 'DECISION',
        decision:           d.decision          ?? '',
        rationale:          d.rationale         ?? '',
        context:            d.context,
        owner:              d.owner             ?? 'enterprise_architect',
        target_date:        d.target_date       ?? null,
        waiver_expiry_date: d.waiver_expiry_date ?? null,
      }))
      allAdrs.push(...domainAdrs)

      domainResults.push({
        domain:   agentDomain,
        score:    domainScore,
        findings: [...domainFindings, ...blockerFindings],
      })

      console.log(`Domain ${agentDomain}: rag_score=${domainScore}, findings=${domainFindings.length}, blockers=${blockerFindings.length}, actions=${domainActions.length}, adrs=${domainAdrs.length}`)
    }

    // ── Aggregate ─────────────────────────────────────────────────────────────

    const domainScores: Record<string, number> = {}
    for (const r of domainResults) domainScores[r.domain] = r.score

    const scores = Object.values(domainScores)
    const aggregateScore = scores.length > 0
      ? Math.round(scores.reduce((sum, s) => sum + s, 0) / scores.length)
      : 3

    const decision = this.determineDecision(aggregateScore, allFindings, domainScores)

    console.log(`\n=== Aggregate Results ===`)
    console.log(`Decision: ${decision}, Agg score: ${aggregateScore}, Findings: ${allFindings.length}`)
    console.log(`Actions: ${allActions.length}, ADRs: ${allAdrs.length}, Tokens: ${totalTokensUsed}`)

    // fullReport preserves original form_data and adds the ai_review section
    const fullReport = {
      ...(reportJson ?? {}),
      ai_review: {
        decision,
        aggregate_score:   aggregateScore,
        domain_scores:     domainScores,
        findings:          allFindings,
        recommendations:   allRecommendations,
        actions:           allActions,
        adrs:              allAdrs,
        processed_at:      new Date().toISOString(),
      },
    }

    return {
      decision,
      aggregateScore,
      domainScores,
      findings:    allFindings,
      adrs:        allAdrs,
      actions:     allActions,
      fullReport,
      tokensUsed:  totalTokensUsed,
      rawResponse: JSON.stringify({ decision, aggregate_score: aggregateScore, domain_scores: domainScores }),
    }
  }

  // ── System prompt (spec: role + rules + scoring) ──────────────────────────

  private buildDomainSystemPrompt(domainLabel: string): string {
    return `You are the ${domainLabel} specialist agent in the Pre-ARB AI Agent pipeline.
Your role is to validate the Solution Architect's submitted artifacts against
enterprise architecture standards and produce a structured JSON review payload.

RULES:
1. Respond ONLY with a valid JSON object matching DomainReviewPayload schema.
   No preamble, no markdown, no explanation outside the JSON.
2. Every finding must reference a specific SA artifact AND a specific KB document.
   Never generate findings from general knowledge alone.
3. Every Blocker must have rag_score = 1 and appear in both findings[] and blockers[].
4. Every finding with rag_score <= 3 (AMBER or RED) must have at least one Action in actions[].
5. Every significant architectural decision or deviation must have an ADR in adrs[].
6. ADRs of type WAIVER must include a proposed waiver_expiry_date (ISO date string).
7. summary.rag_score must equal min(all finding rag_scores). You cannot score AMBER if any finding is RED.
8. If evidence is absent for a mandatory check, set rag_score = 1 (RED). Never skip mandatory categories.
9. Do not invent evidence. If it is not present in the provided artifacts, flag its absence explicitly.
10. Security domain rule: any finding with rag_score < 4 must generate a Blocker record.

SCORING RULES:
5 = Fully compliant — all evidence present, no gaps
4 = Compliant with minor tracked actions only
3 = Partially compliant — gaps exist but mitigation plan is documented
2 = Significant gaps — mandatory remediation actions required before go-live
1 = Fails mandatory standard OR evidence is absent (RED / BLOCKER)`
  }

  // ── User prompt (spec: session + KB + artifacts + checklist + ID seed + categories + schema) ──

  private buildDomainUserPrompt(opts: {
    sessionId:        string
    reportJson:       any
    domainCode:       string
    kbContext:        string
    checklistContext: string
    artefactContext:  string
    nfrContext:       string
    checkCategories:  Array<{ category: string; isMandatoryGreen: boolean }>
  }): string {
    const {
      sessionId, reportJson, domainCode,
      kbContext, checklistContext, artefactContext, nfrContext, checkCategories,
    } = opts

    const fd              = reportJson?.form_data ?? {}
    const solutionName    = fd.solution_name ?? fd.project_name ?? '(not provided)'
    const reviewDate      = new Date().toISOString()
    const solutionContext = buildSolutionContextBlock(reportJson)

    // Mandatory check categories block
    const categoriesBlock = checkCategories.length > 0
      ? checkCategories
          .map(c => c.isMandatoryGreen
            ? `  [MANDATORY-GREEN] ${c.category}  ← non_compliant or not_answered = BLOCKER`
            : `  ${c.category}`)
          .join('\n')
      : '  (no categories registered for this domain — use check_category from the checklist below)'

    // NFR block appended to artefact section if present
    const artefactSection = nfrContext
      ? `${artefactContext}\n\n${nfrContext}`
      : artefactContext

    return `== REVIEW SESSION ==
session_id: ${sessionId}
solution_name: ${solutionName}
domain_under_review: ${domainCode}
review_date: ${reviewDate}

${solutionContext}

== KNOWLEDGE BASE CONTEXT (retrieved for this domain) ==
${kbContext || '(No knowledge base entries are loaded for this domain. Flag findings based on absence of KB evidence.)'}

== SA SUBMITTED ARTIFACTS ==
${artefactSection}

== SA CHECKLIST ANSWERS & EVIDENCE ==
${checklistContext}

== ID SEED ==
finding_id_start:        ${domainCode}-F01
blocker_id_start:        ${domainCode}-BLK-01
recommendation_id_start: ${domainCode}-REC-01
action_id_start:         ${domainCode}-ACT-01
adr_id_start:            ADR-${domainCode}-01
Use these as starting IDs, incrementing sequentially (F01, F02, F03 …).

== MANDATORY CHECK CATEGORIES FOR THIS DOMAIN ==
Produce at least one Finding for each category below.
Categories marked [MANDATORY-GREEN] require rag_score = 1 if the SA answer is non_compliant or not_answered.

${categoriesBlock}

== OUTPUT SCHEMA ==
Return a JSON object with this exact top-level structure. No markdown. No prose outside the JSON.

{
  "domain": "${domainCode}",
  "session_id": "${sessionId}",
  "summary": {
    "rag_score": 3,
    "rag_label": "GREEN | AMBER | RED",
    "rationale": "One-sentence justification for the domain rag_score",
    "total_findings": 0,
    "blocker_count": 0,
    "mandatory_gaps": 0
  },
  "blockers": [
    {
      "id": "${domainCode}-BLK-01",
      "finding_ref": "${domainCode}-F01",
      "description": "Precise description of the blocking issue",
      "resolution_required": "Specific action that must be completed before approval"
    }
  ],
  "recommendations": [
    {
      "id": "${domainCode}-REC-01",
      "finding_ref": "${domainCode}-F01",
      "recommendation": "Specific improvement recommendation",
      "priority": "HIGH | MEDIUM | LOW"
    }
  ],
  "findings": [
    {
      "id": "${domainCode}-F01",
      "check_category": "CATEGORY_FROM_LIST_ABOVE",
      "rag_score": 1,
      "rag_label": "GREEN | AMBER | RED",
      "finding": "Clear description referencing the specific SA artifact gap and relevant KB document",
      "artifact_ref": "File name or section in SA submission where evidence was sought",
      "kb_ref": "KB document ID or title that defines the standard",
      "principle_id": "EA principle code if applicable, else null"
    }
  ],
  "actions": [
    {
      "id": "${domainCode}-ACT-01",
      "finding_ref": "${domainCode}-F01",
      "action": "Specific, measurable remediation step",
      "owner_role": "solution_architect | enterprise_architect | dev_team | security_team",
      "due_days": 30,
      "priority": "HIGH | MEDIUM | LOW"
    }
  ],
  "adrs": [
    {
      "id": "ADR-${domainCode}-01",
      "type": "DECISION | WAIVER",
      "decision": "Decision title",
      "rationale": "Why this decision is being made",
      "context": "Background context (optional)",
      "owner": "Role or team responsible",
      "target_date": "YYYY-MM-DD or null",
      "waiver_expiry_date": "YYYY-MM-DD — required when type = WAIVER, else null"
    }
  ]
}`
  }

  // ── Decision logic (rag_score-based; spec security rule baked in) ─────────

  private determineDecision(
    aggregateScore: number,
    findings: Finding[],
    domainScores: Record<string, number>
  ): 'approve' | 'approve_with_conditions' | 'defer' | 'reject' {
    const blockerCount = findings.filter(f => f.severity === 'critical').length
    const majorCount   = findings.filter(f => f.severity === 'major').length

    // Security domain: rag_score < 4 is already a blocker per rule 10
    const securityScore = domainScores?.security ?? domainScores?.infra ?? 5
    const nfrScore      = domainScores?.nfr ?? 5

    if (blockerCount > 0 || securityScore < 3 || nfrScore < 3) return 'reject'
    if (majorCount >= 3)                                        return 'defer'
    if (majorCount >= 1 || aggregateScore < 4)                  return 'approve_with_conditions'
    return 'approve'
  }
}
