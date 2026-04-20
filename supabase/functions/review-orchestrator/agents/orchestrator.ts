import { DomainAgent, DomainResult, Finding } from './domain-agent.ts'
import { callLLM } from '../utils/llm.ts'

export interface ReviewInput {
  review: any
  artifactText: string
  knowledgeBase: string
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
    const { review, artifactText, knowledgeBase, domainAgents, scopeTags } = input
    
    console.log(`Orchestrator: Starting validation for review ${review.id}`)
    console.log(`Scope tags: ${scopeTags.join(', ')}`)
    
    // Run domain validation for each scope tag
    const domainResults: DomainResult[] = []
    for (const tag of scopeTags) {
      const agent = domainAgents[tag]
      if (agent) {
        console.log(`Running ${tag} domain validation...`)
        const result = agent.validate(artifactText, knowledgeBase)
        domainResults.push(result)
      }
    }
    
    // Aggregate results
    const domainScores: Record<string, number> = {}
    const allFindings: Finding[] = []
    
    for (const result of domainResults) {
      domainScores[result.domain] = result.score
      allFindings.push(...result.findings)
    }
    
    // Calculate aggregate score
    const scores = Object.values(domainScores)
    const aggregateScore = scores.length > 0 
      ? Math.round(scores.reduce((sum, score) => sum + score, 0) / scores.length)
      : 3
    
    console.log(`Aggregate score: ${aggregateScore}`)
    console.log(`Total findings: ${allFindings.length}`)
    
    // Assemble LLM prompt
    const systemPrompt = this.buildSystemPrompt(knowledgeBase, scopeTags)
    const userPrompt = this.buildUserPrompt(review, artifactText, domainResults)
    
    // Call LLM
    const llmResponse = await callLLM({
      systemPrompt,
      userPrompt,
      model: review.llm_model || 'gpt-4o'
    })
    
    // Parse LLM response
    const llmReport = JSON.parse(llmResponse.content)
    
    // Merge domain agent findings with LLM findings
    const mergedFindings = this.mergeFindings(allFindings, llmReport.findings || [])
    
    // Determine decision
    const decision = this.determineDecision(aggregateScore, mergedFindings, llmReport)
    
    return {
      decision,
      aggregateScore,
      domainScores,
      findings: mergedFindings,
      adrs: llmReport.adrs || [],
      actions: llmReport.actions || [],
      fullReport: llmReport,
      tokensUsed: llmResponse.tokensUsed,
      rawResponse: llmResponse.content
    }
  }
  
  private buildSystemPrompt(knowledgeBase: string, scopeTags: string[]): string {
    return `You are an Enterprise Architecture Review Board AI agent.

## Knowledge base — EA principles and standards
${knowledgeBase}

## Review rubric
For each domain (${scopeTags.join(', ')}):
- Score 1-5 (1=critical gap, 5=fully compliant)
- Security and DR must score ≥ 4 for approval
- Cite the specific principle_id from the knowledge base for every finding

## Output schema (respond ONLY in this JSON, no prose)
{
  "decision": "approve|approve_with_conditions|defer|reject",
  "aggregate_score": 1-5,
  "domain_scores": { "app": n, "integration": n, "data": n, "security": n, "infra": n, "devsecops": n },
  "findings": [{ "domain": "", "principle_id": "", "severity": "critical|major|minor", "finding": "", "recommendation": "" }],
  "adrs": [{ "id": "", "decision": "", "rationale": "", "owner": "", "target_date": "" }],
  "actions": [{ "action": "", "owner_role": "", "due_days": n }]
}`
  }
  
  private buildUserPrompt(review: any, artifactText: string, domainResults: DomainResult[]): string {
    const domainSummary = domainResults
      .map(r => `- ${r.domain}: Score ${r.score}, ${r.findings.length} findings`)
      .join('\n')
    
    return `Review the following solution architecture document against the EA principles and standards provided.

Solution Name: ${review.solution_name}
Declared Scope: ${review.scope_tags.join(', ')}

## Domain Agent Analysis
${domainSummary}

## Solution Artifact Content
${artifactText}`
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
    llmReport: any
  ): 'approve' | 'approve_with_conditions' | 'defer' | 'reject' {
    // Use LLM decision if provided, otherwise calculate based on scores
    if (llmReport.decision) {
      return llmReport.decision
    }
    
    const criticalCount = findings.filter(f => f.severity === 'critical').length
    const majorCount = findings.filter(f => f.severity === 'major').length
    
    // Check security and DR scores (must be >= 4)
    const securityScore = llmReport.domain_scores?.security || 0
    const nfrScore = llmReport.domain_scores?.nfr || 0
    
    if (criticalCount > 0 || securityScore < 4 || nfrScore < 4) {
      return 'reject'
    }
    
    if (majorCount >= 3) {
      return 'defer'
    }
    
    if (majorCount >= 1 || aggregateScore < 4) {
      return 'approve_with_conditions'
    }
    
    return 'approve'
  }
}
