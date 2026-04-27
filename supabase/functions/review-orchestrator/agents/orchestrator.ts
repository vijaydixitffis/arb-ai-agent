import { DomainAgent, DomainResult, Finding } from './domain-agent.ts'
import { callLLM } from '../utils/llm.ts'
import {
  buildDomainContext,
  buildSolutionContextBlock,
  buildArtefactBlock,
  buildNfrCriteriaBlock,
  getKnowledgeBaseContent,
  getKbCategoriesForAgent
} from './context-builder.ts'
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export interface ReviewInput {
  review: any
  reportJson: any
  artifactText: string
  supabase: SupabaseClient
  domainAgents: Record<string, DomainAgent>
  scopeTags: string[]
}

export interface ReviewResult {
  decision: 'approve' | 'approve_with_conditions' | 'defer' | 'reject'
  aggregateScore: number
  domainScores: Record<string, number>
  findings: Finding[]
  adrs: Array<{
    id: string
    decision: string
    rationale: string
    owner: string
    target_date: string
  }>
  actions: Array<{
    action: string
    owner_role: string
    due_days: number
  }>
  fullReport: any
  tokensUsed: number
  rawResponse: string
}

export class OrchestratorAgent {
  async validateReview(input: ReviewInput): Promise<ReviewResult> {
    const { review, reportJson, artifactText, supabase, scopeTags } = input
    
    console.log(`Orchestrator: Starting validation for review ${review.id}`)
    console.log(`Scope tags: ${scopeTags.join(', ')}`)
    
    // Map scope tags to agent domains
    const agentDomainMap: Record<string, string[]> = {
      'general': ['general'],
      'business': ['business'],
      'application': ['application', 'software'],
      'integration': ['integration', 'api'],
      'data': ['data'],
      'infrastructure': ['infra', 'security'],
      'devsecops': ['devsecops', 'engg_quality'],
      'nfr': ['nfr', 'security']
    }
    
    // Get all agent domains to process
    const allAgentDomains = scopeTags.flatMap(tag => agentDomainMap[tag] || [tag])
    const uniqueDomains = [...new Set(allAgentDomains)]
    
    console.log(`Processing domains: ${uniqueDomains.join(', ')}`)
    
    // Process each domain with per-domain LLM call
    const domainResults: DomainResult[] = []
    const allFindings: Finding[] = []
    let totalTokensUsed = 0
    
    for (const agentDomain of uniqueDomains) {
      console.log(`\n=== Processing domain: ${agentDomain} ===`)
      
      // Step 1: Load domain checklist + evidence from report_json
      const checklistContext = await buildDomainContext(supabase, reportJson, agentDomain)
      
      // Step 2: Load artifact parsed text (filtered by domain)
      const artefactContext = buildArtefactBlock(reportJson, agentDomain)
      
      // Step 3 & 4: Already done in buildDomainContext (enrich + group by category)
      
      // Step 5: Inject RAG knowledge-base context
      const kbCategories = getKbCategoriesForAgent(agentDomain)
      const kbContext = await getKnowledgeBaseContent(supabase, kbCategories)
      
      // Step 6: Assemble final prompt and call LLM
      const systemPrompt = this.buildDomainSystemPrompt(agentDomain, kbContext)
      const userPrompt = this.buildDomainUserPrompt(
        review,
        reportJson,
        checklistContext,
        artefactContext,
        agentDomain
      )
      
      // Add NFR criteria for NFR domain
      let nfrContext = ''
      if (agentDomain === 'nfr') {
        nfrContext = buildNfrCriteriaBlock(reportJson)
      }
      
      const finalUserPrompt = userPrompt + '\n\n' + nfrContext
      
      console.log(`Calling LLM for domain: ${agentDomain}`)
      const llmResponse = await callLLM({
        systemPrompt,
        userPrompt: finalUserPrompt,
        model: review.llm_model || 'gpt-4o'
      })
      
      totalTokensUsed += llmResponse.tokensUsed
      
      // Parse domain-specific LLM response
      const domainReport = JSON.parse(llmResponse.content)
      
      // Extract findings from domain response
      const domainFindings: Finding[] = (domainReport.findings || []).map((f: any) => ({
        domain: agentDomain,
        principle_id: f.principle_id || '',
        severity: f.severity || 'minor',
        finding: f.finding || '',
        recommendation: f.recommendation || ''
      }))
      
      allFindings.push(...domainFindings)
      
      // Calculate domain score from findings
      const domainScore = this.calculateDomainScore(domainFindings)
      domainResults.push({
        domain: agentDomain,
        score: domainScore,
        findings: domainFindings
      })
      
      console.log(`Domain ${agentDomain}: score=${domainScore}, findings=${domainFindings.length}`)
    }
    
    // Aggregate results
    const domainScores: Record<string, number> = {}
    for (const result of domainResults) {
      domainScores[result.domain] = result.score
    }
    
    // Calculate aggregate score
    const scores = Object.values(domainScores)
    const aggregateScore = scores.length > 0 
      ? Math.round(scores.reduce((sum, score) => sum + score, 0) / scores.length)
      : 3
    
    console.log(`\n=== Aggregate Results ===`)
    console.log(`Aggregate score: ${aggregateScore}`)
    console.log(`Total findings: ${allFindings.length}`)
    console.log(`Total tokens used: ${totalTokensUsed}`)
    
    // Determine decision
    const decision = this.determineDecision(aggregateScore, allFindings, domainScores)
    
    // Build final report
    const fullReport = {
      decision,
      aggregate_score: aggregateScore,
      domain_scores: domainScores,
      findings: allFindings,
      solution_context: buildSolutionContextBlock(reportJson)
    }
    
    return {
      decision,
      aggregateScore,
      domainScores,
      findings: allFindings,
      adrs: [], // ADRs would be extracted from LLM responses if needed
      actions: [], // Actions would be extracted from LLM responses if needed
      fullReport,
      tokensUsed: totalTokensUsed,
      rawResponse: JSON.stringify(fullReport)
    }
  }
  
  private buildDomainSystemPrompt(agentDomain: string, kbContext: string): string {
    return `You are an Enterprise Architecture Review Board AI agent specializing in the ${agentDomain} domain.

## KNOWLEDGE BASE CONTEXT
${kbContext}

## YOUR TASK
Review the SA checklist answers and evidence provided below. Generate findings grouped by check_category.

## OUTPUT SCHEMA (respond ONLY in this JSON, no prose)
{
  "findings": [
    {
      "check_category": "CATEGORY_NAME",
      "severity": "blocker|high|medium|low|info",
      "finding": "Clear description of the issue",
      "recommendation": "Specific actionable recommendation",
      "principle_id": "Reference to relevant principle if applicable"
    }
  ]
}

## SEVERITY GUIDELINES
- blocker: mandatory_green questions with non_compliant or not_answered
- high: important questions with non_compliant and no evidence
- medium: important questions with non_compliant/partial and weak evidence
- low: advisory questions with issues
- info: minor observations or suggestions

## BLANK EVIDENCE HANDLING
If evidence is blank for non_compliant or partial answers, explicitly cite "absence of evidence" in the finding.`
  }
  
  private buildDomainUserPrompt(
    review: any,
    reportJson: any,
    checklistContext: string,
    artefactContext: string,
    agentDomain: string
  ): string {
    const solutionContext = buildSolutionContextBlock(reportJson)
    
    return `${solutionContext}

${checklistContext}

${artefactContext}`
  }
  
  private calculateDomainScore(findings: Finding[]): number {
    if (findings.length === 0) return 5
    
    const blockerCount = findings.filter(f => f.severity === 'blocker').length
    const highCount = findings.filter(f => f.severity === 'high').length
    const mediumCount = findings.filter(f => f.severity === 'medium').length
    const lowCount = findings.filter(f => f.severity === 'low').length
    
    // Scoring algorithm based on severity
    if (blockerCount > 0) return 1
    if (highCount >= 3) return 1
    if (highCount >= 1) return 2
    if (mediumCount >= 5) return 2
    if (mediumCount >= 3) return 3
    if (mediumCount >= 1) return 4
    if (lowCount >= 5) return 4
    
    return 5
  }
  
  private mergeFindings(agentFindings: Finding[], llmFindings: Finding[]): Finding[] {
    // Merge findings from domain agents and LLM
    // Prioritize LLM findings but include agent findings as additional context
    const merged = [...llmFindings]
    
    // Add agent findings that aren't duplicates
    for (const agentFinding of agentFindings) {
      const isDuplicate = merged.some(
        llmFinding => 
          llmFinding.principle_id === agentFinding.principle_id &&
          llmFinding.finding === agentFinding.finding
      )
      
      if (!isDuplicate) {
        merged.push(agentFinding)
      }
    }
    
    return merged
  }
  
  private determineDecision(
    aggregateScore: number,
    findings: Finding[],
    domainScores: Record<string, number>
  ): 'approve' | 'approve_with_conditions' | 'defer' | 'reject' {
    const blockerCount = findings.filter(f => f.severity === 'blocker').length
    const highCount = findings.filter(f => f.severity === 'high').length
    
    // Check security and NFR scores (must be >= 4)
    const securityScore = domainScores?.security || 0
    const nfrScore = domainScores?.nfr || 0
    
    if (blockerCount > 0 || securityScore < 4 || nfrScore < 4) {
      return 'reject'
    }
    
    if (highCount >= 3) {
      return 'defer'
    }
    
    if (highCount >= 1 || aggregateScore < 4) {
      return 'approve_with_conditions'
    }
    
    return 'approve'
  }
}
