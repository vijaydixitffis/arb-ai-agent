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
  solution:     'Solution',
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
  solution:     'SOL',
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
  aggregateRagLabel: string
  domainScores: Record<string, number>
  domainSummaries: Record<string, any>
  findings: Finding[]
  blockers: any[]
  adrs: DomainAdr[]
  actions: DomainAction[]
  recommendations: any[]
  nfrScorecard: any[]
  kbSourcesCited: string[]
  fullReport: any
  tokensUsed: number
  rawResponse: string
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function ragScoreToSeverity(ragScore: number): 'BLOCKER' | 'HIGH' | 'MEDIUM' | 'LOW' | 'INFO' {
  if (ragScore <= 1) return 'BLOCKER'
  if (ragScore <= 2) return 'HIGH'
  if (ragScore === 3) return 'MEDIUM'
  if (ragScore === 4) return 'LOW'
  return 'INFO'
}

function scoreToRagLabel(score: number): string {
  if (score >= 4) return 'GREEN'
  if (score === 3) return 'AMBER'
  return 'RED'
}

// ── Orchestrator ──────────────────────────────────────────────────────────────

// Delay between sequential domain LLM calls — stays within 15 RPM free-tier limit.
const INTER_DOMAIN_DELAY_S = 0.5

// One retry on transient LLM errors (503, timeout, etc.), 10 s delay.
// Retry (attempt 2) reduces KB + artefact content by 25% to stay under token limits.
const LLM_CONTENT_SCALE_ON_SECOND_RETRY = 0.75

export class OrchestratorAgent {
  async validateReview(input: ReviewInput): Promise<ReviewResult> {
    const { review, reportJson, artifactText, supabase, scopeTags } = input

    console.log(`Orchestrator: Starting validation for review ${review.id}`)
    console.log(`Scope tags: ${scopeTags.join(', ')}`)

    const agentDomainMap: Record<string, string[]> = {
      solution:       ['solution'],
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

    const domainResults:      DomainResult[] = []
    const allFindings:        Finding[]      = []
    const allBlockers:        any[]          = []
    const allAdrs:            DomainAdr[]    = []
    const allActions:         DomainAction[] = []
    const allRecommendations: any[]          = []
    const allNfrScorecard:    any[]          = []
    const domainSummaries:    Record<string, any> = {}
    const kbSourcesCited:     string[]       = []
    let totalTokensUsed = 0

    for (const agentDomain of uniqueDomains) {
      console.log(`\n=== Processing domain: ${agentDomain} ===`)

      const domainResult = await this._processDomainWithRetry(
        review, reportJson, artifactText, supabase, agentDomain
      )

      totalTokensUsed += domainResult.tokensUsed
      allFindings.push(...domainResult.findings)
      allBlockers.push(...domainResult.blockers)
      allAdrs.push(...domainResult.adrs)
      allActions.push(...domainResult.actions)
      allRecommendations.push(...domainResult.recommendations)
      if (domainResult.nfrScorecard.length > 0) allNfrScorecard.push(...domainResult.nfrScorecard)
      if (domainResult.kbRefs.length > 0) kbSourcesCited.push(...domainResult.kbRefs)

      domainSummaries[agentDomain] = domainResult.domainSummary
      domainResults.push({
        domain:   agentDomain,
        score:    domainResult.score,
        findings: domainResult.findings,
      })

      if (agentDomain !== uniqueDomains[uniqueDomains.length - 1]) {
        await new Promise(r => setTimeout(r, INTER_DOMAIN_DELAY_S * 1000))
      }
    }

    // ── Aggregate (spec: MIN, not mean; security/DR blocker overrides to 1) ──

    const domainScores: Record<string, number> = {}
    for (const r of domainResults) domainScores[r.domain] = r.score

    const scores = Object.values(domainScores)
    let aggregateScore = scores.length > 0 ? Math.min(...scores) : 3
    const hasSecurityDrBlocker = allBlockers.some(b => b.is_security_or_dr)
    if (hasSecurityDrBlocker) aggregateScore = 1

    const aggregateRagLabel = scoreToRagLabel(aggregateScore)
    const decision = this.determineDecision(aggregateScore, allBlockers)

    console.log(`\n=== Aggregate Results ===`)
    console.log(`Decision: ${decision}, Agg score: ${aggregateScore} (${aggregateRagLabel}), Blockers: ${allBlockers.length}`)
    console.log(`Findings: ${allFindings.length}, Actions: ${allActions.length}, ADRs: ${allAdrs.length}, Tokens: ${totalTokensUsed}`)

    const fullReport = {
      ...(reportJson ?? {}),
      ai_review: {
        decision,
        recommended_decision:  decision,
        aggregate_score:       aggregateScore,
        aggregate_rag_label:   aggregateRagLabel,
        domain_scores:         domainScores,
        domain_summaries:      domainSummaries,
        findings:              allFindings,
        blockers:              allBlockers,
        recommendations:       allRecommendations,
        actions:               allActions,
        adrs:                  allAdrs,
        nfr_scorecard:         allNfrScorecard,
        kb_sources_cited:      [...new Set(kbSourcesCited)],
        processed_at:          new Date().toISOString(),
      },
    }

    return {
      decision,
      aggregateScore,
      aggregateRagLabel,
      domainScores,
      domainSummaries,
      findings:      allFindings,
      blockers:      allBlockers,
      adrs:          allAdrs,
      actions:       allActions,
      recommendations: allRecommendations,
      nfrScorecard:  allNfrScorecard,
      kbSourcesCited: [...new Set(kbSourcesCited)],
      fullReport,
      tokensUsed:    totalTokensUsed,
      rawResponse:   JSON.stringify(fullReport.ai_review),
    }
  }

  // ── System prompt (spec: role + rules + scoring) ──────────────────────────

  private buildDomainSystemPrompt(domainLabel: string, agentDomain: string = ''): string {
    const solutionExtra = agentDomain === 'solution' ? `

SOLUTION DOMAIN — SPECIALIST GUIDANCE:
As the Solution reviewer your primary responsibility is to assess whether this submission is
problem-driven, well-defined, and strategically aligned — not just technically complete.

KEY ASSESSMENT AREAS (generate a finding for each, even if artefacts are absent):
- PROBLEM_STATEMENT_QUALITY: Is the problem clearly articulated, customer-grounded, and measurable?
  Vague or generic problem statement → rag_score 2.  Absent problem statement → rag_score 1.
  Clear, specific, measurable problem linked to a customer or business pain → rag_score 4–5.
- SOLUTION_FIT: Does the proposed solution directly address the root cause of the stated problem?
  Assess alignment between the problem description and the architectural approach in the artefacts.
- BUSINESS_OUTCOMES: Are target outcomes Specific, Measurable, Achievable, Relevant, Time-bound?
  Generic outcomes ("improve performance") without metrics → rag_score 2–3.
  SMART outcomes with measurable KPIs and timelines → rag_score 4–5.
- STAKEHOLDER_ALIGNMENT: Are key stakeholders identified with clear ownership and accountability?
- STRATEGIC_FIT: Does the solution align with the stated enterprise business drivers?

WEIGHTING — PROBLEM STATEMENT:
The problem statement quality carries significant weight in the overall domain score.
A solution with strong technical artefacts but a vague or absent problem statement should score
no higher than rag_score 3 (AMBER) overall.
A well-framed problem with SMART outcomes and demonstrated solution-fit warrants rag_score 4–5.

OUTPUT ADDITION — include "project_context" as the first key in your JSON response:
{
  "project_context": {
    "problem_statement_assessed": "Brief restatement of the SA's problem as you understood it",
    "problem_statement_quality": "clear | vague | absent",
    "outcomes_measurability": "measurable | partial | not_measurable | absent",
    "solution_fit_assessment": "One sentence: how well the solution addresses the stated problem"
  }
}` : ''

    return `You are a senior ${domainLabel} architect acting as a specialist reviewer in the Pre-ARB AI Agent pipeline.
Your role is to conduct a thorough, proportionate review of the Solution Architect's submission against
enterprise architecture standards — producing a balanced assessment that reflects real-world ARB practice.

RULES:
1. Respond ONLY with a valid JSON object matching DomainReviewPayload schema.
   No preamble, no markdown, no explanation outside the JSON.

2. Every finding MUST reference a specific SA artifact section OR a relevant KB document.
   Focus on material gaps affecting architecture quality, security, or operability.
   When the SA has addressed a requirement with reasonable evidence (even if not in the prescribed format),
   credit it and note the finding as GREEN or AMBER rather than inventing a gap.

3. RAG scoring — calibrate proportionately:
   • rag_score 1 (BLOCKER): Critical gaps preventing approval — unmitigated security risks,
     absent mandatory compliance evidence, critical domain with no design at all.
   • rag_score 2 (RED): Significant gaps requiring mandatory remediation before go-live.
   • rag_score 3 (AMBER): Gaps present but a clear remediation path exists; trackable post-approval.
   • rag_score 4 (GREEN+): Area well-addressed; only minor follow-up actions logged.
   • rag_score 5 (GREEN): Fully addressed — key evidence present, approach aligns with EA standards.
   Reserve rag_score 1–2 for genuinely critical issues. Prefer AMBER (3) for non-critical gaps.
   Use rag_score 4 liberally when the SA has done solid work with minor loose ends.

4. Every finding with rag_score <= 3 (AMBER or RED) MUST have at least one Action in actions[].

5. Generate ADRs only for decisions that warrant formal recording (aim for 0–3 per domain):
   - Technology or vendor choices that deviate from EA standards → type: DECISION
   - Architectural patterns that differ materially from the standard approach → type: DECISION
   - Any rag_score 1–2 finding where the SA needs a formal exception → type: WAIVER
   Do NOT generate ADRs for straightforward remediation items or routine AMBER findings.
   adrs[] may be empty if no significant decisions or exceptions were identified.

6. ADRs of type WAIVER must include a proposed waiver_expiry_date (ISO date string).

7. summary.rag_score reflects overall domain readiness — calibrate against the finding distribution:
   - Mostly GREEN (4–5) with 1–2 minor AMBERs → summary GREEN (4)
   - Mix of GREEN and AMBER, no blockers → summary AMBER (3)
   - Any rag_score=2 finding OR multiple AMBERs without mitigations → summary RED (2)
   - Any blocker (rag_score=1) → summary RED (1)
   The summary should represent what an ARB panel would conclude about this domain's readiness.

8. When evidence is absent, apply proportionate judgment:
   - Critical domain (security controls, DR/HA, compliance): absent evidence → rag_score 1–2
   - Non-critical / advisory: absent evidence → rag_score 3 with a documented action
   - Evidence quality matters: a vague "will be addressed post-launch" does NOT satisfy a mandatory check.
     Require a documented plan, owner, and timeline to credit rag_score 3; anything weaker is rag_score 2.
   - Evidence that addresses the INTENT of a requirement in alternate format: credit appropriately.

9. Do not invent evidence. Flag genuine absences explicitly — note WHAT is missing and WHY it matters.
   When the SA has documented their rationale for a deviation, assess whether the rationale is adequate
   rather than automatically flagging as non-compliant.

10. Security domain: any rag_score ≤ 2 finding requires a corresponding Blocker entry.

PRAGMATISM GUIDELINES:
- Calibrate against the solution's risk profile. A customer-facing, regulated system warrants stricter
  scrutiny than an internal analytics tool. Let the problem statement and stakeholder context inform weight.
- Distinguish mandatory enterprise standards from best-practice guidance. Flag violations of the former
  as RED/AMBER; treat the latter as recommendations with LOW priority.
- The knowledge base may not cover every scenario. Where KB guidance is sparse, apply professional
  judgment informed by the solution's context and general architecture principles.
- Accept evidence addressing the INTENT of a requirement, even if not in the exact prescribed format.
- For intentional design trade-offs (e.g., MVP simplicity over full resilience), assess whether the
  trade-off is proportionate, documented, and time-bounded — not just whether it follows the standard.
- When the SA has made a well-reasoned deviation with documented rationale, acknowledge it explicitly
  and assess the rationale's adequacy rather than treating silence and bad reasoning the same way.

COVERAGE REQUIREMENT:
- Assess every check category listed in the prompt. For fully addressed categories,
  a GREEN finding (rag_score 4–5) that briefly acknowledges compliance IS the correct output.
  Do not manufacture concerns for well-covered areas. Do not skip any category.

SCORING RULES:
5 = Fully compliant — key evidence present, approach clearly aligned with EA standards, no material gaps
4 = Compliant — area well-addressed; only minor tracked actions remain (e.g., doc update, monitoring config)
3 = Partially compliant — material gaps present but SA has a credible, time-bound remediation plan
2 = Significant gaps — mandatory remediation required; go-live should be conditional on resolution
1 = Fails mandatory standard OR critical evidence absent with no documented mitigation (BLOCKER)${solutionExtra}`
  }

  // ── User prompt (spec: session + KB + artifacts + checklist + ID seed + categories + schema) ──

  private buildDomainUserPrompt(opts: {
    sessionId:        string
    reportJson:       any
    domainCode:       string
    agentDomain:      string
    kbContext:        string
    checklistContext: string
    artefactContext:  string
    nfrContext:       string
    checkCategories:  Array<{ category: string; isMandatoryGreen: boolean }>
  }): string {
    const {
      sessionId, reportJson, domainCode, agentDomain,
      kbContext, checklistContext, artefactContext, nfrContext, checkCategories,
    } = opts

    const fd           = reportJson?.form_data ?? {}
    const solutionName = fd.solution_name ?? fd.project_name ?? '(not provided)'
    const reviewDate   = new Date().toISOString()

    // For Solution domain: dedicated project info block; for others: standard context block
    const solutionContext = agentDomain === 'solution'
      ? (() => {
          const problem   = fd.problem_statement ?? '(not provided)'
          const drivers   = (fd.business_drivers ?? []).join('; ') || '(not provided)'
          const stk       = (fd.stakeholders ?? []).join(', ') || '(not provided)'
          const outcomes  = fd.target_business_outcomes ?? fd.growth_plans ?? '(not provided)'
          return `== PROJECT INFORMATION (PRIMARY ASSESSMENT CONTEXT) ==
Solution Name:            ${solutionName}
Problem Statement:        ${problem}
Business Drivers:         ${drivers}
Stakeholders:             ${stk}
Target Business Outcomes: ${outcomes}

ASSESSMENT INSTRUCTIONS:
1. Assess QUALITY of the problem statement — not just presence. A strong problem statement identifies
   the customer/stakeholder, describes the pain or opportunity, quantifies impact, and is specific
   enough to evaluate solution-fit.
2. Assess whether target outcomes are SMART (Specific, Measurable, Achievable, Relevant, Time-bound).
3. Assess solution-fit: does the architectural approach in the artefacts directly address the problem?
4. Generate PROBLEM_STATEMENT_QUALITY and BUSINESS_OUTCOMES findings regardless of other coverage.`
        })()
      : buildSolutionContextBlock(reportJson)

    // Mandatory check categories block
    const categoriesBlock = checkCategories.length > 0
      ? checkCategories
          .map(c => c.isMandatoryGreen
            ? `  [MANDATORY-GREEN] ${c.category}  ← non_compliant = BLOCKER (check artifact evidence first)`
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
Assess each category below and produce a finding that accurately reflects the actual state:
  - Fully compliant area → GREEN finding (rag_score 4–5) briefly acknowledging coverage is the correct output.
  - Partial compliance or minor gap → AMBER finding (rag_score 3) with a time-bound action.
  - Critical gap or non-compliant mandatory check → RED finding (rag_score 1–2) with a blocker or action.
Do not manufacture concerns for well-addressed areas. Do not skip any listed category.
Categories marked [MANDATORY-GREEN] require rag_score = 1 if the SA answer is non_compliant
(check artifact evidence first — adequate mitigating evidence can raise this to rag_score 2).

${categoriesBlock}

== OUTPUT SCHEMA ==
Return a JSON object with this exact top-level structure. No markdown. No prose outside the JSON.
${agentDomain === 'solution' ? `
Include "project_context" as the first key (Solution domain only):
  "project_context": {
    "problem_statement_assessed": "Brief restatement of the SA's problem as you understood it",
    "problem_statement_quality": "clear | vague | absent",
    "outcomes_measurability": "measurable | partial | not_measurable | absent",
    "solution_fit_assessment": "One sentence: how well the solution addresses the stated problem"
  },
` : ''}
{
  "domain": "${domainCode}",
  "session_id": "${sessionId}",
  "summary": {
    "rag_score": 3,
    "rag_label": "GREEN | AMBER | RED",
    "overall_readiness": "READY | READY_WITH_CONDITIONS | NOT_READY",
    "rationale": "One-sentence justification for the domain rag_score",
    "executive_summary": "2-3 sentence narrative of domain readiness for the ARB panel",
    "compliant_areas": ["area1", "area2"],
    "gap_areas": ["gap1", "gap2"],
    "total_findings": 0,
    "blocker_count": 0,
    "action_count": 0,
    "adr_count": 0,
    "evidence_quality": "STRONG | ADEQUATE | WEAK | ABSENT",
    "domain_specific_scores": { "sub_area_name": 4 },
    "kb_references": ["KB doc title or ID cited"]
  },
  "blockers": [
    {
      "id": "${domainCode}-BLK-01",
      "domain": "${domainCode}",
      "title": "Short blocker title",
      "description": "Precise description of the blocking issue",
      "violated_standard": "Which EA standard or policy is violated",
      "impact": "Business or technical impact if not resolved",
      "resolution_required": "Specific action that must be completed before approval",
      "links_to_finding_id": "${domainCode}-F01",
      "is_security_or_dr": false,
      "status": "OPEN",
      "kb_evidence_ref": ["KB doc title"]
    }
  ],
  "recommendations": [
    {
      "id": "${domainCode}-REC-01",
      "domain": "${domainCode}",
      "priority": "HIGH | MEDIUM | LOW",
      "title": "Short recommendation title",
      "rationale": "Why this is recommended",
      "approved_pattern_ref": "EA-approved pattern name if applicable",
      "benefit": "Expected benefit of implementing this recommendation",
      "implementation_hint": "How to implement (optional)",
      "applies_to_finding_id": "${domainCode}-F01",
      "is_agent_generated": true,
      "kb_source_ref": ["KB doc title"]
    }
  ],
  "findings": [
    {
      "id": "${domainCode}-F01",
      "check_category": "CATEGORY_FROM_LIST_ABOVE",
      "rag_score": 4,
      "rag_label": "GREEN | AMBER | RED",
      "title": "Short finding title",
      "finding": "Balanced assessment: what the SA addressed well and any specific gap (reference artifact or KB)",
      "recommendation": "Specific, actionable remediation if a gap exists; omit or 'no action required' if GREEN",
      "evidence_source": "File name or section in SA submission where evidence was reviewed",
      "standard_violated": "Which standard is not met (null if compliant)",
      "impact": "Impact of this gap if not addressed (null if GREEN)",
      "is_blocker": false,
      "waiver_eligible": false,
      "links_to_action_ids": ["${domainCode}-ACT-01"],
      "links_to_adr_id": null,
      "artifact_ref": "File name or section in SA submission",
      "kb_ref": "KB document ID or title that defines the standard",
      "principle_id": "EA principle code if applicable, else null",
      "kb_reference": ["KB doc title"]
    }
  ],
  "actions": [
    {
      "id": "${domainCode}-ACT-01",
      "domain": "${domainCode}",
      "action_type": "MANDATORY | RECOMMENDED | CONDITIONAL",
      "title": "Short action title",
      "finding_ref": "${domainCode}-F01",
      "action": "Specific, measurable remediation step",
      "owner_role": "solution_architect | enterprise_architect | dev_team | security_team",
      "proposed_owner": "solution_architect",
      "due_days": 30,
      "proposed_due_date": "YYYY-MM-DD or null",
      "priority": "HIGH | MEDIUM | LOW",
      "verification_method": "How EA will verify this is done",
      "is_conditional_approval_gate": false,
      "links_to_finding_id": "${domainCode}-F01",
      "links_to_blocker_id": null
    }
  ],
  "adrs": [
    {
      "id": "ADR-${domainCode}-01",
      "domain": "${domainCode}",
      "type": "DECISION | WAIVER",
      "adr_type": "DECISION | WAIVER",
      "title": "Short ADR title",
      "decision": "Formal decision statement",
      "rationale": "Why this decision is being made",
      "context": "Background context (optional)",
      "consequences": "Trade-offs and implications",
      "options_considered": [{"option": "option name", "pros": "pros", "cons": "cons"}],
      "mitigations": ["mitigation step"],
      "owner": "Role or team responsible",
      "proposed_owner": "Role or team",
      "target_date": "YYYY-MM-DD or null",
      "proposed_target_date": "YYYY-MM-DD or null",
      "waiver_expiry_date": "YYYY-MM-DD — required when type = WAIVER, else null",
      "links_to_finding_ids": ["${domainCode}-F01"],
      "links_to_action_ids": [],
      "kb_references": ["KB doc title"]
    }
  ]${agentDomain === 'nfr' ? `,
  "nfr_scorecard": [
    {
      "nfr_category": "SCALABILITY_PERFORMANCE | HA_RESILIENCE | SECURITY | DEVSECOPS_QUALITY | ENGINEERING_EXCELLENCE | DR",
      "rag_score": 3,
      "rag_label": "GREEN | AMBER | RED",
      "evidence_provided": ["evidence item"],
      "gaps": ["gap description"],
      "slo_target": "e.g. 99.9% availability",
      "actual_evidenced": "What the SA evidenced",
      "is_mandatory_green": false
    }
  ]` : ''}
}`
  }

  // ── Retry wrapper (matches Python implementation) ───────────────────────────

  private async _processDomainWithRetry(
    review: any,
    reportJson: any,
    artifactText: string,
    supabase: any,
    agentDomain: string
  ): Promise<{
    score: number
    domainSummary: any
    findings: Finding[]
    blockers: any[]
    adrs: DomainAdr[]
    actions: DomainAction[]
    recommendations: any[]
    nfrScorecard: any[]
    kbRefs: string[]
    tokensUsed: number
  }> {
    const domainCode = DOMAIN_CODE[agentDomain] ?? agentDomain.toUpperCase()
    const domainLabel = DOMAIN_LABEL[agentDomain] ?? agentDomain

    const delays = [0, 10] // 2 total attempts, 10s delay on retry
    let lastErr: Error = new Error('no attempts made')

    for (let attempt = 1; attempt <= delays.length; attempt++) {
      const delay = delays[attempt - 1]
      const contentScale = attempt === 2 ? LLM_CONTENT_SCALE_ON_SECOND_RETRY : 1.0

      if (delay > 0) {
        console.warn(`[ORCHESTRATOR] ${agentDomain} attempt ${attempt} — retrying in ${delay}s after: ${lastErr.message}`)
        await new Promise(r => setTimeout(r, delay * 1000))
      }

      if (contentScale < 1.0) {
        console.log(`[ORCHESTRATOR] ${agentDomain} attempt ${attempt} — reducing KB/artefact content to ${Math.round(contentScale * 100)}%`)
      }

      try {
        // 1. Checklist + evidence enriched by question_registry
        const checklistContext = await buildDomainContext(supabase, reportJson, agentDomain)

        // 2. Check categories for mandatory coverage instruction
        const registry = await getRegistryForAgent(supabase, agentDomain)
        const checkCategories = extractCheckCategories(registry)

        // 3. Artefact block — with content scaling on retry
        const artefactBlock = buildArtefactBlock(reportJson, agentDomain)
        const artefactContext = artefactBlock.includes('none available') && artifactText
          ? `== PARSED ARTEFACT (raw extraction) ==\n${artifactText.slice(0, Math.floor(8000 * contentScale))}`
          : artefactBlock

        // 4. NFR quantitative criteria (nfr domain only)
        const nfrContext = agentDomain === 'nfr' ? buildNfrCriteriaBlock(reportJson) : ''

        // 5. Knowledge-base RAG context — with scaled limits (matches Python: 8 domain + 4 general)
        const kbCategories = getKbCategoriesForAgent(agentDomain)
        const kbDomLimit = Math.max(1, Math.floor(8 * contentScale))
        const kbGenLimit = Math.max(1, Math.floor(4 * contentScale))
        const kbContext = await getKnowledgeBaseContent(supabase, kbCategories, undefined, kbDomLimit + kbGenLimit)

        // 6. Build prompts per spec structure
        const systemPrompt = this.buildDomainSystemPrompt(domainLabel, agentDomain)
        const userPrompt = this.buildDomainUserPrompt({
          sessionId: review.id,
          reportJson,
          domainCode,
          agentDomain,
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
          model: review.llm_model || Deno.env.get('OPENROUTER_MODEL') || Deno.env.get('GEMINI_MODEL') || 'gemini-2.5-flash-lite',
        })

        // 7. Parse DomainReviewPayload (handles markdown fences)
        let domainReport: any
        try {
          domainReport = parseJsonFromLLM(llmResponse.content)
        } catch (parseErr: any) {
          console.error(`JSON parse failed for domain ${agentDomain}:`, parseErr)
          console.error('Raw LLM content (first 500 chars):', llmResponse.content.slice(0, 500))
          domainReport = { summary: { rag_score: 3 }, findings: [], blockers: [], recommendations: [], actions: [], adrs: [] }
        }

        // Domain score — LLM-authoritative via summary.rag_score
        const domainScore: number = (() => {
          const raw = Number(domainReport.summary?.rag_score)
          return raw >= 1 && raw <= 5 ? Math.round(raw) : 3
        })()
        const domainRagLabel = scoreToRagLabel(domainScore)

        // rec lookup for fallback recommendation text on findings
        const recByFindingRef: Record<string, string> = {}
        for (const rec of (domainReport.recommendations ?? [])) {
          const ref  = rec.finding_ref || rec.id
          const text = (rec.recommendation ?? rec.rationale ?? '').trim()
          if (ref && text) recByFindingRef[ref] = text
        }

        // Findings (extended fields)
        const domainFindings: Finding[] = (domainReport.findings ?? []).map((f: any) => {
          const findingId   = (f.id ?? f.finding_id ?? '').trim()
          const principleId = (f.principle_id ?? '').trim() || findingId || ''
          const inlineRec   = (f.recommendation ?? '').trim()
          return {
            domain:              agentDomain,
            principle_id:        principleId,
            finding_id:          findingId,
            severity:            ragScoreToSeverity(Number(f.rag_score) || 3),
            finding:             f.finding ?? f.description ?? '',
            recommendation:      inlineRec || recByFindingRef[findingId] || '',
            check_category:      f.check_category ?? '',
            title:               f.title ?? null,
            rag_score:           Number(f.rag_score) || 3,
            evidence_source:     f.evidence_source ?? null,
            standard_violated:   f.standard_violated ?? null,
            impact:              f.impact ?? null,
            is_blocker:          f.is_blocker ?? false,
            links_to_action_ids: f.links_to_action_ids ?? [],
            links_to_adr_id:     f.links_to_adr_id ?? null,
            waiver_eligible:     f.waiver_eligible ?? false,
            kb_reference:        f.kb_reference ?? [],
            artifact_ref:        f.artifact_ref ?? null,
            kb_ref:              f.kb_ref ?? null,
          }
        })

        // Blockers as separate table rows (not merged into findings)
        const domainBlockers = (domainReport.blockers ?? []).map((b: any) => ({
          blocker_id:         b.id ?? b.blocker_id ?? `${domainCode}-BLK-${Date.now()}`,
          domain:             agentDomain,
          title:              b.title ?? b.description ?? '',
          description:        b.description ?? b.title ?? '',
          violated_standard:  b.violated_standard ?? null,
          impact:             b.impact ?? null,
          resolution_required: b.resolution_required ?? '',
          links_to_finding_id: b.finding_ref ?? b.links_to_finding_id ?? null,
          is_security_or_dr:  b.is_security_or_dr ?? (agentDomain === 'security' || agentDomain === 'infra'),
          status:             b.status ?? 'OPEN',
          kb_evidence_ref:    b.kb_evidence_ref ?? [],
        }))

        // Recommendations (extended fields)
        const domainRecommendations = (domainReport.recommendations ?? []).map((r: any) => ({
          recommendation_id:    r.id ?? r.recommendation_id ?? `${domainCode}-REC-${Date.now()}`,
          domain:               agentDomain,
          priority:             r.priority ?? 'MEDIUM',
          title:                r.title ?? null,
          rationale:            r.rationale ?? r.recommendation ?? '',
          approved_pattern_ref: r.approved_pattern_ref ?? null,
          benefit:              r.benefit ?? null,
          implementation_hint:  r.implementation_hint ?? null,
          applies_to_finding_id: r.finding_ref ?? r.applies_to_finding_id ?? null,
          applies_to_adr_id:    r.applies_to_adr_id ?? null,
          is_agent_generated:   true,
          kb_source_ref:        r.kb_source_ref ?? [],
        }))

        // Actions (extended fields)
        const domainActions: DomainAction[] = (domainReport.actions ?? []).map((a: any) => ({
          id:                         a.id ?? `${domainCode}-ACT-${Date.now()}`,
          finding_ref:                a.finding_ref ?? '',
          action:                     a.action ?? '',
          owner_role:                 a.owner_role ?? a.proposed_owner ?? 'solution_architect',
          due_days:                   Number(a.due_days) || 30,
          priority:                   a.priority ?? 'MEDIUM',
          // extended
          action_id:                  a.id ?? a.action_id ?? null,
          domain:                     agentDomain,
          action_type:                a.action_type ?? null,
          title:                      a.title ?? null,
          proposed_owner:             a.proposed_owner ?? a.owner_role ?? null,
          proposed_due_date:          a.proposed_due_date ?? null,
          verification_method:        a.verification_method ?? null,
          is_conditional_approval_gate: a.is_conditional_approval_gate ?? false,
          links_to_finding_id:        a.finding_ref ?? a.links_to_finding_id ?? null,
          links_to_blocker_id:        a.links_to_blocker_id ?? null,
          links_to_adr_id:            a.links_to_adr_id ?? null,
        }))

        // ADRs (extended fields)
        const domainAdrs: DomainAdr[] = (domainReport.adrs ?? []).map((d: any) => ({
          id:                 d.id ?? `ADR-${domainCode}-${Date.now()}`,
          type:               d.type ?? 'DECISION',
          decision:           d.decision ?? '',
          rationale:          d.rationale ?? '',
          context:            d.context,
          owner:              d.owner ?? 'enterprise_architect',
          target_date:        d.target_date ?? null,
          waiver_expiry_date: d.waiver_expiry_date ?? null,
          // extended
          domain:             agentDomain,
          adr_type:           d.type ?? d.adr_type ?? 'DECISION',
          title:              d.title ?? d.decision ?? null,
          options_considered: d.options_considered ?? null,
          mitigations:        d.mitigations ?? [],
          proposed_owner:     d.owner ?? d.proposed_owner ?? null,
          proposed_target_date: d.target_date ?? d.proposed_target_date ?? null,
          links_to_finding_ids: d.links_to_finding_ids ?? [],
          links_to_action_ids:  d.links_to_action_ids ?? [],
          kb_references:        d.kb_references ?? [],
        }))

        // NFR scorecard (only populated by the nfr domain agent)
        const domainNfrScorecard = (domainReport.nfr_scorecard ?? []).map((n: any) => ({
          nfr_category:      n.nfr_category ?? n.category ?? '',
          rag_score:         Number(n.rag_score) || 3,
          rag_label:         n.rag_label ?? scoreToRagLabel(Number(n.rag_score) || 3),
          evidence_provided: n.evidence_provided ?? [],
          gaps:              n.gaps ?? [],
          mitigating_condition: n.mitigating_condition ?? null,
          slo_target:        n.slo_target ?? null,
          actual_evidenced:  n.actual_evidenced ?? null,
          is_mandatory_green: n.is_mandatory_green ?? false,
        }))

        const kbRefs: string[] = domainReport.summary?.kb_references ?? []

        // Full DomainSummary object for domain_scores table
        const domainSummary = {
          score:                domainScore,
          rag_label:            domainRagLabel,
          overall_readiness:    domainReport.summary?.overall_readiness ?? null,
          executive_summary:    domainReport.summary?.executive_summary ?? domainReport.summary?.rationale ?? null,
          compliant_areas:      domainReport.summary?.compliant_areas ?? [],
          gap_areas:            domainReport.summary?.gap_areas ?? [],
          blocker_count:        domainBlockers.length,
          action_count:         domainActions.length,
          adr_count:            domainAdrs.length,
          domain_specific_scores: domainReport.summary?.domain_specific_scores ?? null,
          evidence_quality:     domainReport.summary?.evidence_quality ?? null,
          kb_references:        kbRefs,
          model_used:           review.llm_model || 'gemini-2.5-flash-lite',
          // for frontend display
          total_findings:       domainFindings.length,
          critical_count:       domainFindings.filter((f: any) => (f.rag_score || 3) <= 2).length,
          findings:             domainFindings,
          actions:              domainActions,
          adrs:                 domainAdrs,
          recommendations:      domainRecommendations,
        }

        console.log(`Domain ${agentDomain}: score=${domainScore}(${domainRagLabel}), findings=${domainFindings.length}, blockers=${domainBlockers.length}, actions=${domainActions.length}, adrs=${domainAdrs.length}`)

        return {
          score:           domainScore,
          domainSummary,
          findings:        domainFindings,
          blockers:        domainBlockers,
          adrs:            domainAdrs,
          actions:         domainActions,
          recommendations: domainRecommendations,
          nfrScorecard:    domainNfrScorecard,
          kbRefs,
          tokensUsed:      llmResponse.tokensUsed,
        }
      } catch (err: any) {
        lastErr = err
        console.warn(`[ORCHESTRATOR] ${agentDomain} attempt ${attempt} failed: ${err.message}`)
      }
    }

    throw lastErr
  }

  // ── Decision logic (spec-correct: MIN aggregate, security/DR override) ──────

  private determineDecision(
    aggregateScore: number,
    blockers: any[],
  ): 'approve' | 'approve_with_conditions' | 'defer' | 'reject' {
    const hasAnyBlocker        = blockers.length > 0
    const hasSecurityDrBlocker = blockers.some(b => b.is_security_or_dr)

    if (aggregateScore >= 4 && !hasAnyBlocker)          return 'approve'
    if (aggregateScore <= 1 && hasSecurityDrBlocker)    return 'reject'
    if (aggregateScore <= 1 || hasAnyBlocker)           return 'defer'
    return 'approve_with_conditions'
  }
}
