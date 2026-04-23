import React, { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Button } from '../components/ui/Button'
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card'
import { Textarea } from '../components/ui/Textarea'
import { ChevronLeft, CheckCircle, XCircle, AlertCircle, Clock } from 'lucide-react'

export default function ReviewDashboard() {
  const navigate = useNavigate()
  const { submissionId } = useParams()
  const [eaDecision, setEADecision] = useState('')
  const [overrideRationale, setOverrideRationale] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchReviewData()
  }, [submissionId])

  const fetchReviewData = async () => {
    try {
      // Mock data - replace with Supabase queries when ready
      // const review = await api.getReviewBySubmission(submissionId || '')
      setLoading(false)
    } catch (error) {
      console.error('Error fetching review data:', error)
      setLoading(false)
    }
  }

  // Mock data - in production, fetch from API
  const submission = {
    id: submissionId,
    project_name: 'Customer 360 Platform',
    solution_architect: 'John Doe',
    submitted_date: '2024-04-09',
    status: 'submitted',
  }

  const agentRecommendation = {
    recommendation: 'APPROVE_WITH_ACTIONS',
    rationale: 'Solution meets most EA standards but requires actions for security documentation and DR testing evidence.',
    overall_score: 78,
    conditions: [
      'Complete security documentation within 30 days',
      'Provide DR test evidence within 60 days',
      'Update API documentation with versioning'
    ],
    target_date: '2024-06-01',
  }

  // Mock data - in production, fetch from API
  // TODO: Update to use dynamic domains from metadata when API integration is implemented
  const validationResults = {
    application: { compliance: 'PARTIALLY_COMPLIANT', score: 75, gaps: ['Missing SBOM documentation'] },
    integration: { compliance: 'COMPLIANT', score: 85, gaps: [] },
    data: { compliance: 'COMPLIANT', score: 90, gaps: [] },
    security: { compliance: 'PARTIALLY_COMPLIANT', score: 70, gaps: ['Missing security architecture documentation'] },
    infrastructure: { compliance: 'COMPLIANT', score: 80, gaps: [] },
    devsecops: { compliance: 'COMPLIANT', score: 85, gaps: [] },
  }

  // TODO: Update to use dynamic NFR categories from metadata when API integration is implemented
  const nfrScores = {
    scalability: { status: 'GREEN', score: 4 },
    ha_dr: { status: 'AMBER', score: 3 },
    security: { status: 'GREEN', score: 4 },
    quality: { status: 'GREEN', score: 4 },
  }

  const adrs = [
    {
      id: 'ADR-1',
      title: 'Action Required: Complete security documentation',
      status: 'OPEN',
      target_date: '2024-05-09',
    },
    {
      id: 'ADR-2',
      title: 'Action Required: Provide DR test evidence',
      status: 'OPEN',
      target_date: '2024-06-09',
    },
  ]

  const handleAccept = async () => {
    try {
      // Mock accept - replace with Supabase query when ready
      // await api.approveReview(submissionId || '')
      navigate('/dashboard')
    } catch (error) {
      console.error('Error accepting review:', error)
      alert('Failed to accept review')
    }
  }

  const handleOverride = async () => {
    if (!eaDecision || !overrideRationale) {
      alert('Please select a decision and provide rationale')
      return
    }
    try {
      // Mock override - replace with Supabase query when ready
      // await api.overrideReview(submissionId || '', eaDecision, overrideRationale)
      navigate('/dashboard')
    } catch (error) {
      console.error('Error overriding review:', error)
      alert('Failed to override review')
    }
  }

  const handleSendBack = async () => {
    try {
      // Implement send back API call
      navigate('/dashboard')
    } catch (error) {
      console.error('Error sending back:', error)
      alert('Failed to send back')
    }
  }

  const getRecommendationBadge = (rec: string) => {
    const badges = {
      APPROVE: { color: 'bg-green-100 text-green-800', icon: CheckCircle },
      APPROVE_WITH_ACTIONS: { color: 'bg-amber-100 text-amber-800', icon: AlertCircle },
      DEFER: { color: 'bg-orange-100 text-orange-800', icon: Clock },
      REJECT: { color: 'bg-red-100 text-red-800', icon: XCircle },
    }
    const badge = badges[rec as keyof typeof badges] || badges.APPROVE
    const Icon = badge.icon
    return { color: badge.color, Icon }
  }

  const getNFRBadge = (status: string) => {
    const colors = {
      GREEN: 'bg-green-100 text-green-800',
      AMBER: 'bg-amber-100 text-amber-800',
      RED: 'bg-red-100 text-red-800',
    }
    return colors[status as keyof typeof colors] || colors.GREEN
  }

  const { color: recColor, Icon: RecIcon } = getRecommendationBadge(agentRecommendation.recommendation)

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <div className="flex items-center gap-4">
            <Button variant="ghost" onClick={() => navigate('/dashboard')}>
              <ChevronLeft className="w-4 h-4" />
            </Button>
            <h1 className="text-2xl font-bold">ARB Review</h1>
          </div>
          <div className="text-sm text-muted-foreground">
            {submission.project_name} ({submission.id})
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8 space-y-6">
        {/* Submission Overview */}
        <Card>
          <CardHeader>
            <CardTitle>Submission Overview</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium text-muted-foreground">Project Name</label>
                <p className="font-medium">{submission.project_name}</p>
              </div>
              <div>
                <label className="text-sm font-medium text-muted-foreground">Solution Architect</label>
                <p className="font-medium">{submission.solution_architect}</p>
              </div>
              <div>
                <label className="text-sm font-medium text-muted-foreground">Submitted Date</label>
                <p className="font-medium">{submission.submitted_date}</p>
              </div>
              <div>
                <label className="text-sm font-medium text-muted-foreground">Status</label>
                <p className="font-medium">{submission.status}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Agent Recommendation */}
        <Card>
          <CardHeader>
            <CardTitle>AI Agent Recommendation</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center gap-3">
                <span className={`px-3 py-1 rounded-full text-sm font-medium flex items-center gap-2 ${recColor}`}>
                  <RecIcon className="w-4 h-4" />
                  {agentRecommendation.recommendation.replace('_', ' ')}
                </span>
                <span className="text-sm text-muted-foreground">
                  Overall Score: {agentRecommendation.overall_score}/100
                </span>
              </div>
              <div>
                <label className="text-sm font-medium">Rationale</label>
                <p className="text-sm mt-1">{agentRecommendation.rationale}</p>
              </div>
              {agentRecommendation.conditions.length > 0 && (
                <div>
                  <label className="text-sm font-medium">Conditions</label>
                  <ul className="list-disc list-inside text-sm mt-1 space-y-1">
                    {agentRecommendation.conditions.map((condition, idx) => (
                      <li key={idx}>{condition}</li>
                    ))}
                  </ul>
                </div>
              )}
              <div>
                <label className="text-sm font-medium">Target Date</label>
                <p className="text-sm mt-1">{agentRecommendation.target_date}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Domain Validation Results */}
        <Card>
          <CardHeader>
            <CardTitle>Domain Validation Results</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-3 gap-4">
              {Object.entries(validationResults).map(([domain, result]) => (
                <div key={domain} className="border rounded-lg p-4">
                  <h4 className="font-medium capitalize mb-2">{domain}</h4>
                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span>Compliance:</span>
                      <span className={`px-2 py-0.5 rounded text-xs ${
                        result.compliance === 'COMPLIANT' ? 'bg-green-100 text-green-800' :
                        result.compliance === 'PARTIALLY_COMPLIANT' ? 'bg-amber-100 text-amber-800' :
                        'bg-red-100 text-red-800'
                      }`}>
                        {result.compliance.replace('_', ' ')}
                      </span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span>Score:</span>
                      <span>{result.score}%</span>
                    </div>
                    {result.gaps.length > 0 && (
                      <div>
                        <span className="text-sm font-medium">Gaps:</span>
                        <ul className="list-disc list-inside text-xs text-muted-foreground">
                          {result.gaps.map((gap, idx) => (
                            <li key={idx}>{gap}</li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* NFR Assessment */}
        <Card>
          <CardHeader>
            <CardTitle>NFR Assessment</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-4 gap-4">
              {Object.entries(nfrScores).map(([category, score]) => (
                <div key={category} className="border rounded-lg p-4 text-center">
                  <h4 className="font-medium capitalize mb-2">{category.replace('_', ' ')}</h4>
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${getNFRBadge(score.status)}`}>
                    {score.status} ({score.score}/5)
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* ADRs */}
        <Card>
          <CardHeader>
            <CardTitle>Architecture Decision Records</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {adrs.map((adr) => (
                <div key={adr.id} className="border rounded-lg p-4 flex justify-between items-center">
                  <div>
                    <p className="font-medium">{adr.title}</p>
                    <p className="text-sm text-muted-foreground">
                      Target: {adr.target_date} | Status: {adr.status}
                    </p>
                  </div>
                  <span className="text-xs px-2 py-1 rounded bg-blue-100 text-blue-800">
                    {adr.id}
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* EA Decision */}
        <Card>
          <CardHeader>
            <CardTitle>Enterprise Architect Decision</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-6">
              <div>
                <label className="block text-sm font-medium mb-3">Accept Agent Recommendation</label>
                <Button onClick={handleAccept} className="w-full sm:w-auto">
                  <CheckCircle className="w-4 h-4 mr-2" />
                  Accept {agentRecommendation.recommendation.replace('_', ' ')}
                </Button>
              </div>

              <div className="border-t pt-6">
                <label className="block text-sm font-medium mb-3">Or Override Decision</label>
                <div className="space-y-4">
                  <div className="flex flex-wrap gap-2">
                    {['APPROVE', 'APPROVE_WITH_ACTIONS', 'DEFER', 'REJECT'].map((decision) => (
                      <button
                        key={decision}
                        onClick={() => setEADecision(decision)}
                        className={`px-4 py-2 rounded-lg text-sm font-medium border transition-colors ${
                          eaDecision === decision
                            ? 'bg-primary text-primary-foreground border-primary'
                            : 'bg-background hover:bg-accent'
                        }`}
                      >
                        {decision.replace('_', ' ')}
                      </button>
                    ))}
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-2">Override Rationale</label>
                    <Textarea
                      value={overrideRationale}
                      onChange={(e) => setOverrideRationale(e.target.value)}
                      placeholder="Provide rationale for overriding the agent recommendation..."
                      rows={4}
                    />
                  </div>
                  <Button onClick={handleOverride} disabled={!eaDecision || !overrideRationale}>
                    <AlertCircle className="w-4 h-4 mr-2" />
                    Override with Rationale
                  </Button>
                </div>
              </div>

              <div className="border-t pt-6">
                <label className="block text-sm font-medium mb-3">Send Back for Rework</label>
                <Button variant="outline" onClick={handleSendBack}>
                  <XCircle className="w-4 h-4 mr-2" />
                  Send Back to Solution Architect
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
