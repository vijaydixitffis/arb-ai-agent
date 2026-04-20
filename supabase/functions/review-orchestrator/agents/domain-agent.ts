export interface Finding {
  domain: string
  principle_id: string
  severity: 'critical' | 'major' | 'minor'
  finding: string
  recommendation: string
}

export interface DomainResult {
  domain: string
  score: number
  findings: Finding[]
}

export abstract class DomainAgent {
  abstract domain: string
  abstract relevantPrinciples: string[]
  
  validate(artifactText: string, mdContent: string): DomainResult {
    const relevantMD = this.extractRelevantMD(mdContent)
    const findings = this.extractFindings(artifactText, relevantMD)
    const score = this.calculateScore(findings)
    
    return {
      domain: this.domain,
      score,
      findings
    }
  }
  
  protected extractRelevantMD(mdContent: string): string {
    // Extract MD sections relevant to this domain
    // This is a simple implementation - can be enhanced with regex parsing
    const lines = mdContent.split('\n')
    const relevantLines: string[] = []
    let inRelevantSection = false
    
    for (const line of lines) {
      // Check if line contains this domain name or relevant principles
      if (this.relevantPrinciples.some(principle => line.includes(principle))) {
        inRelevantSection = true
      }
      
      if (inRelevantSection) {
        relevantLines.push(line)
        
        // Stop at next major section
        if (line.startsWith('## ') && !this.relevantPrinciples.some(principle => line.includes(principle))) {
          inRelevantSection = false
        }
      }
    }
    
    return relevantLines.join('\n')
  }
  
  protected abstract extractFindings(artifactText: string, mdContent: string): Finding[]
  
  protected calculateScore(findings: Finding[]): number {
    if (findings.length === 0) return 5
    
    const criticalCount = findings.filter(f => f.severity === 'critical').length
    const majorCount = findings.filter(f => f.severity === 'major').length
    const minorCount = findings.filter(f => f.severity === 'minor').length
    
    // Scoring algorithm
    if (criticalCount > 0) return 1
    if (majorCount >= 3) return 2
    if (majorCount >= 1) return 3
    if (minorCount >= 5) return 3
    if (minorCount >= 2) return 4
    
    return 5
  }
}
