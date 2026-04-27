// ================================================================
// CONTEXT BUILDER — IMPLEMENTATION GUIDE
// File: src/agents/context-builder.ts
//
// PURPOSE
// -------
// Before every domain-agent LLM call, this module:
//   1. Loads the SA's checklist answers + evidence from report_json
//   2. Loads the domain's questions from question_registry (DB or cache)
//   3. Enriches each answer with question text, check_category, weight
//   4. Groups enriched questions by check_category
//   5. Produces a formatted text block ready for the LLM user message
//
// This is the ONLY place where question codes are resolved to text.
// The LLM never sees raw codes like "app-soft-3".
// ================================================================

import { Pool } from 'pg'   // or your existing DB client

// ── Types ────────────────────────────────────────────────────────

export type ComplianceAnswer = 'compliant' | 'non_compliant' | 'partial' | 'na'

export interface QuestionRegistryRow {
  question_code:       string
  question_text:       string
  frontend_tab:        string
  agent_domain:        string
  check_category:      string
  display_group:       string
  sort_order:          number
  weight:              'mandatory_green' | 'important' | 'advisory'
  is_mandatory_green:  boolean
  blank_nc_severity:   'blocker' | 'high' | 'medium' | 'low' | 'info'
  na_permitted:        boolean
  hint_text:           string | null
}

export interface EnrichedQuestion extends QuestionRegistryRow {
  answer:   ComplianceAnswer | 'not_answered'
  evidence: string   // empty string if SA left it blank
}

// ── Step 1: Load question registry from DB (cache this in memory) ─
//
// INSTRUCTION: Cache this query result in your app's startup sequence
// or in a short-lived in-memory cache (e.g. 1 hour TTL).
// The registry rarely changes and you don't want a DB round-trip on
// every agent dispatch.

const registryCache = new Map<string, QuestionRegistryRow[]>()

export async function getRegistryForAgent(
  db:          Pool,
  agentDomain: string,
  schemaVersion: string = '1.0'
): Promise<QuestionRegistryRow[]> {

  const cacheKey = `${agentDomain}:${schemaVersion}`
  if (registryCache.has(cacheKey)) return registryCache.get(cacheKey)!

  const { rows } = await db.query<QuestionRegistryRow>(`
    SELECT *
    FROM   public.question_registry
    WHERE  agent_domain   = $1
      AND  schema_version = $2
      AND  is_active      = true
    ORDER  BY sort_order
  `, [agentDomain, schemaVersion])

  registryCache.set(cacheKey, rows)
  return rows
}

// ── Step 2: Map agent domain to the frontend tab key(s) it reads ──
//
// INSTRUCTION: Some agents share a frontend tab.
// This function returns the list of tab keys to read from
// report_json.form_data.domain_data.

export function getFrontendTabsForAgent(agentDomain: string): string[] {
  // Most agents read from one tab; security reads from TWO tabs
  const map: Record<string, string[]> = {
    general:      ['general'],
    business:     ['business'],
    application:  ['application'],   // reads app-meta-* and app-oth-*
    software:     ['application'],   // reads app-soft-* from same tab
    integration:  ['integration'],   // reads int-cat-* and int-nfr-*
    api:          ['integration'],   // reads int-check-* from same tab
    security:     ['infrastructure', 'nfr'],  // infra-sec-* + nfr-sec-*
    data:         ['data'],
    infra:        ['infrastructure'], // reads infra-meta-* and infra-oth-*
    devsecops:    ['devsecops'],      // reads devops-* and secops-*
    engg_quality: ['devsecops'],      // reads engex-* from same tab
    nfr:          ['nfr'],            // reads nfr-ha-* and nfr-scalar-*
  }
  return map[agentDomain] ?? [agentDomain]
}

// ── Step 3: Extract checklist + evidence from report_json ─────────
//
// INSTRUCTION: Merge answers from all relevant frontend tabs into
// a single flat map. For agents that read from multiple tabs
// (e.g. security reads infrastructure + nfr), merge both.

export function extractAnswers(
  reportJson:  any,
  frontendTabs: string[]
): { checklist: Record<string, ComplianceAnswer>; evidence: Record<string, string> } {

  const checklist: Record<string, ComplianceAnswer> = {}
  const evidence:  Record<string, string> = {}

  for (const tab of frontendTabs) {
    const tabData = reportJson?.form_data?.domain_data?.[tab]
    if (!tabData) continue

    // Merge checklist answers
    for (const [code, answer] of Object.entries(tabData.checklist ?? {})) {
      checklist[code] = answer as ComplianceAnswer
    }
    // Merge evidence comments
    for (const [code, text] of Object.entries(tabData.evidence ?? {})) {
      evidence[code] = (text as string).trim()
    }
  }

  return { checklist, evidence }
}

// ── Step 4: Enrich — join answers with registry ───────────────────
//
// INSTRUCTION: Every question in the registry for this agent gets
// a row. Questions the SA answered get their answer + evidence.
// Questions NOT answered by the SA get answer='not_answered'.
// not_answered on a mandatory_green question = BLOCKER.

export function enrichQuestions(
  registry:  QuestionRegistryRow[],
  checklist: Record<string, ComplianceAnswer>,
  evidence:  Record<string, string>
): EnrichedQuestion[] {

  return registry.map(q => ({
    ...q,
    answer:   checklist[q.question_code] ?? 'not_answered',
    evidence: evidence[q.question_code] ?? '',
  }))
}

// ── Step 5: Group by check_category, then format for LLM ─────────
//
// INSTRUCTION: Group questions by check_category and render a
// structured text block. The LLM is instructed to produce ONE
// finding per check_category group — not one per question.
// This keeps findings at the right level of granularity.

export function formatChecklistBlock(
  enriched:    EnrichedQuestion[],
  agentDomain: string
): string {

  // Group by check_category, preserving sort order within each group
  const groups = new Map<string, EnrichedQuestion[]>()
  for (const q of enriched) {
    if (!groups.has(q.check_category)) groups.set(q.check_category, [])
    groups.get(q.check_category)!.push(q)
  }

  const totalQ = enriched.length
  const lines: string[] = [
    `== SA CHECKLIST — domain: ${agentDomain} (${totalQ} questions) ==`,
    '',
    'INSTRUCTIONS FOR THIS SECTION:',
    '  • Generate ONE finding per check_category group, not one per question code.',
    '  • For mandatory_green categories: non_compliant or not_answered = BLOCKER',
    '    regardless of evidence. Set is_mandatory_green=true, rag_score=1.',
    '  • For blank evidence on non_compliant/partial: treat as absent evidence.',
    '    Raise the finding at the blank_nc_severity shown; cite absence explicitly.',
    '  • For not_answered questions: treat as non_compliant with no evidence.',
    '  • For compliant answers: only raise a finding if evidence reveals a concern.',
    '  • Skip na answers unless the hint_text suggests na requires justification.',
    '',
  ]

  for (const [category, questions] of groups) {
    const isMandatory = questions.some(q => q.is_mandatory_green)
    const flag = isMandatory ? '  ⚠ MANDATORY-GREEN — non_compliant = BLOCKER' : ''
    lines.push(`── check_category: ${category}${flag}`)

    for (const q of questions) {
      const answerTag = formatAnswer(q.answer)
      const evidenceTag = formatEvidence(q.answer, q.evidence)
      const hint = q.hint_text ? `\n           Hint:     ${q.hint_text}` : ''

      lines.push(`  ${q.question_code.padEnd(15)} ${q.question_text}`)
      lines.push(`           Answer:   ${answerTag}`)
      lines.push(`           Evidence: ${evidenceTag}${hint}`)

      // Inline severity guidance for non-green answers
      if (['non_compliant', 'partial', 'not_answered'].includes(q.answer)) {
        const sev = q.is_mandatory_green
          ? 'BLOCKER  (mandatory-green rule)'
          : q.blank_nc_severity.toUpperCase() +
            (q.evidence ? '' : '  (blank evidence — treat as absent)')
        lines.push(`           → Raise ${sev} finding for ${category}`)
      }
    }
    lines.push('')
  }

  return lines.join('\n')
}

function formatAnswer(answer: string): string {
  const labels: Record<string, string> = {
    compliant:     'COMPLIANT',
    non_compliant: 'NON-COMPLIANT ✗',
    partial:       'PARTIAL △',
    na:            'N/A',
    not_answered:  'NOT ANSWERED ✗',
  }
  return labels[answer] ?? answer.toUpperCase()
}

function formatEvidence(answer: string, evidence: string): string {
  if (evidence) return `"${evidence}"`
  if (answer === 'compliant' || answer === 'na') return '(none — acceptable for this answer)'
  return '(none provided — treat as absent evidence)'
}

// ── Step 6: Assemble the full domain agent context ────────────────
//
// INSTRUCTION: Call buildDomainContext() in your orchestrator/agent
// wrapper just before constructing the LLM API call. Pass the
// returned contextBlock as the checklist section of the user message.
//
// Usage:
//   const ctx = await buildDomainContext(db, reportJson, 'application')
//   // then in your LLM user message:
//   const userMessage = [
//     '== KNOWLEDGE BASE CONTEXT ==',
//     ragContextText,           // from RAG agent
//     '',
//     '== SA SOLUTION CONTEXT ==',
//     solutionContextBlock(reportJson),  // problem statement, stakeholders etc.
//     '',
//     ctx,                      // enriched checklist block from this function
//     '',
//     '== PARSED ARTEFACT TEXT ==',
//     artefactText,             // from artefact_uploads[].parsed_text
//     '',
//     '== OUTPUT SCHEMA ==',
//     outputSchemaBlock,
//   ].join('\n')

export async function buildDomainContext(
  db:          Pool,
  reportJson:  any,
  agentDomain: string,
  schemaVersion: string = '1.0'
): Promise<string> {

  // 1. Load registry for this agent (cached after first call)
  const registry = await getRegistryForAgent(db, agentDomain, schemaVersion)

  // 2. Determine which frontend tab(s) this agent reads from
  const tabs = getFrontendTabsForAgent(agentDomain)

  // 3. Extract raw answers + evidence from the stored JSON
  const { checklist, evidence } = extractAnswers(reportJson, tabs)

  // 4. Enrich with registry metadata
  const enriched = enrichQuestions(registry, checklist, evidence)

  // 5. Format into LLM-ready text block
  return formatChecklistBlock(enriched, agentDomain)
}

// ── Step 7: Helper — solution context block ───────────────────────
//
// INSTRUCTION: Prepend this to every domain agent call so the LLM
// always has the solution's purpose, stakeholders and growth plans
// without you having to repeat them per domain.

export function buildSolutionContextBlock(reportJson: any): string {
  const fd = reportJson?.form_data ?? {}
  const lines = [
    '== SOLUTION CONTEXT ==',
    `Solution Name:      ${fd.solution_name ?? fd.project_name ?? '(not provided)'}`,
    `Problem Statement:  ${fd.problem_statement ?? '(not provided)'}`,
    `Stakeholders:       ${(fd.stakeholders ?? []).join(', ') || '(not provided)'}`,
    `Business Drivers:   ${(fd.business_drivers ?? []).join('; ') || '(not provided)'}`,
    `Growth Plans:       ${fd.growth_plans ?? '(not provided)'}`,
  ]
  return lines.join('\n')
}

// ── Step 8: Helper — artefact text block ─────────────────────────
//
// INSTRUCTION: For each domain agent, only pass artefact text that
// is tagged to that domain. Do not send all artefacts to all agents
// — it bloats the context window unnecessarily.
// Truncate individual artefact text to MAX_ARTEFACT_CHARS to avoid
// a single large diagram consuming the whole context window.

const MAX_ARTEFACT_CHARS = 4000  // tune based on your context budget

export function buildArtefactBlock(
  reportJson:  any,
  agentDomain: string
): string {

  const uploads: any[] = reportJson?.artefact_uploads ?? []

  // Filter to artefacts tagged for this domain
  // An artefact with no domain_tags is sent to ALL agents
  const relevant = uploads.filter(u =>
    u.parse_status === 'complete' &&
    u.parsed_text &&
    (u.domain_tags?.length === 0 ||
     !u.domain_tags ||
     u.domain_tags.includes(agentDomain))
  )

  if (relevant.length === 0) return '== PARSED ARTEFACTS — none available for this domain =='

  const lines = [`== PARSED ARTEFACTS — ${relevant.length} file(s) for domain: ${agentDomain} ==`]

  for (const u of relevant) {
    lines.push(`\n--- ${u.file_name} (${u.artefact_category ?? 'other'}) ---`)
    const text = (u.parsed_text as string).slice(0, MAX_ARTEFACT_CHARS)
    lines.push(text)
    if (u.parsed_text.length > MAX_ARTEFACT_CHARS) {
      lines.push(`[... truncated — full text in artefact_id: ${u.artefact_id}]`)
    }
  }

  return lines.join('\n')
}

// ── Step 9: Handle the NFR quantitative criteria ──────────────────
//
// INSTRUCTION: The NFRAgent additionally needs the quantitative
// nfr_criteria rows (target vs actual values). Build a separate
// block for these and append it to the NFR agent context.

export function buildNfrCriteriaBlock(reportJson: any): string {
  const rows: any[] = reportJson?.form_data?.nfr_criteria ?? []
  if (rows.length === 0) return '== NFR CRITERIA — none provided by SA =='

  const lines = [
    `== NFR QUANTITATIVE CRITERIA (${rows.length} rows) ==`,
    'These are the SA-entered target vs actual values. Use them to calibrate',
    'SCALABILITY_PERFORMANCE and HA_RESILIENCE scores in the nfr_scorecard.',
    '',
    'Category           | Criteria              | Target      | Actual       | SA Score | Evidence',
    '-------------------|----------------------|-------------|--------------|----------|----------',
  ]

  for (const r of rows) {
    const cat      = (r.category     ?? '').padEnd(18)
    const criteria = (r.criteria     ?? '').padEnd(21)
    const target   = (r.target_value ?? '').padEnd(11)
    const actual   = (r.actual_value ?? '').padEnd(12)
    const score    = String(r.score ?? '?').padEnd(8)
    const evidence = r.evidence ?? '(none)'
    lines.push(`${cat} | ${criteria} | ${target} | ${actual} | ${score} | ${evidence}`)
  }

  return lines.join('\n')
}

// ── EXISTING DATA — what to do with already-stored reviews ────────
//
// NOTHING needs to change in the database for existing reviews.
// The question codes in report_json.form_data.domain_data.*.checklist
// are stable — they were always stored as bare key→answer pairs
// (e.g. { "app-soft-3": "non_compliant" }).
//
// The question_registry is a lookup-at-call-time resource, not
// something stored per-review. When you re-run or replay an agent
// on an older review, buildDomainContext() enriches those same
// stored codes with the current registry at that moment.
//
// Three edge cases for existing data:
//
// CASE 1 — SA answered a question that was later retired (is_active=false)
//   The code will be in checklist but not in the registry query result
//   (because WHERE is_active=true filters it out). The enrichQuestions()
//   function will simply not produce a row for it — it is silently
//   dropped. This is the correct behaviour: retired questions should
//   not produce findings.
//   ACTION: None required.
//
// CASE 2 — A new mandatory_green question was added after a review was
//   submitted (SA never saw it on the form)
//   The registry will have a row for it; the checklist won't have an
//   answer. enrichQuestions() maps it to answer='not_answered'.
//   The formatChecklistBlock() will emit a BLOCKER hint for it.
//   For older reviews you do NOT want this behaviour — you want to
//   skip questions the SA was never asked.
//   ACTION: Either (a) filter by schema_version matching the review's
//   submitted schema, or (b) treat not_answered as 'na' for questions
//   added after the review's submitted_at date. The schema_version
//   column on question_registry supports option (a).
//
// CASE 3 — Evidence field is absent entirely (older frontend versions
//   may not have populated the evidence object at all)
//   extractAnswers() defaults to empty string '' when the key is
//   missing. The formatEvidence() function treats '' as
//   "none provided" and flags it accordingly.
//   ACTION: None required — handled gracefully.
//
// SUMMARY: Re-running the context builder on any existing review
// works correctly without any data migration, subject to the
// schema_version caveat in Case 2.

export default buildDomainContext
