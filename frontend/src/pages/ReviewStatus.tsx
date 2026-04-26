import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { reviewService, ReviewStatus as ReviewStatusType } from '../services/backendConfig'
import { ArrowLeft, CheckCircle, XCircle, Clock, AlertCircle, FileText, Target, AlertTriangle } from 'lucide-react'

export default function ReviewStatus() {
  const { reviewId } = useParams<{ reviewId: string }>()
  const navigate = useNavigate()
  const [reviewStatus, setReviewStatus] = useState<ReviewStatusType | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [polling, setPolling] = useState(false)

  useEffect(() => {
    if (!reviewId) {
      setError('Review ID not provided')
      setLoading(false)
      return
    }

    // Initial fetch
    fetchReviewStatus()

    // Start polling if not complete
    const startPolling = async () => {
      setPolling(true)
      try {
        await reviewService.pollReviewStatus(
          reviewId,
          (status) => {
            setReviewStatus(status)
          },
          5000, // Poll every 5 seconds
          60 // Max 60 attempts (5 minutes)
        )
      } catch (err) {
        console.error('Polling error:', err)
        setError(err instanceof Error ? err.message : 'Failed to poll review status')
      } finally {
        setPolling(false)
      }
    }

    startPolling()
  }, [reviewId])

  const fetchReviewStatus = async () => {
    try {
      setLoading(true)
      const status = await reviewService.getReviewStatus(reviewId!)
      setReviewStatus(status)
    } catch (err) {
      console.error('Error fetching review status:', err)
      setError(err instanceof Error ? err.message : 'Failed to fetch review status')
    } finally {
      setLoading(false)
    }
  }

  const getStatusIcon = () => {
    if (!reviewStatus) return <Clock className="w-8 h-8 text-gray-400" />
    
    switch (reviewStatus.status) {
      case 'pending':
        return <Clock className="w-8 h-8 text-yellow-500 animate-pulse" />
      case 'in_review':
        return <Clock className="w-8 h-8 text-blue-500 animate-spin" />
      case 'ea_review':
        return <CheckCircle className="w-8 h-8 text-green-500" />
      case 'approved':
        return <CheckCircle className="w-8 h-8 text-green-600" />
      case 'rejected':
        return <XCircle className="w-8 h-8 text-red-600" />
      case 'deferred':
        return <AlertCircle className="w-8 h-8 text-orange-500" />
      default:
        return <Clock className="w-8 h-8 text-gray-400" />
    }
  }

  const getStatusText = () => {
    if (!reviewStatus) return 'Loading...'
    
    switch (reviewStatus.status) {
      case 'pending':
        return 'Pending - Waiting to start'
      case 'in_review':
        return 'In Review - AI Agent is processing'
      case 'ea_review':
        return 'EA Review - Ready for Enterprise Architect review'
      case 'approved':
        return 'Approved'
      case 'rejected':
        return 'Rejected'
      case 'deferred':
        return 'Deferred'
      default:
        return 'Unknown Status'
    }
  }

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical':
        return 'bg-red-100 text-red-800 border-red-200'
      case 'major':
        return 'bg-orange-100 text-orange-800 border-orange-200'
      case 'minor':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200'
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200'
    }
  }

  const getScoreColor = (score: number) => {
    if (score >= 4) return 'text-green-600'
    if (score >= 3) return 'text-yellow-600'
    return 'text-red-600'
  }

  if (loading && !reviewStatus) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gray-900 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading review status...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Card className="max-w-md w-full mx-4">
          <CardHeader>
            <CardTitle className="text-red-600">Error</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-gray-600 mb-4">{error}</p>
            <Button onClick={() => navigate('/dashboard')} className="w-full">
              Return to Dashboard
            </Button>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Button variant="outline" size="sm" onClick={() => navigate('/dashboard')}>
                <ArrowLeft className="w-4 h-4 mr-2" />
                Back to Dashboard
              </Button>
              <h1 className="text-xl font-semibold">Review Status</h1>
            </div>
            <div className="flex items-center gap-2">
              {getStatusIcon()}
              <span className="font-medium">{getStatusText()}</span>
            </div>
          </div>
        </div>
      </div>

      <main className="max-w-7xl mx-auto px-4 py-8">
        {reviewStatus && (
          <div className="space-y-6">
            {/* Status Card */}
            <Card>
              <CardHeader>
                <CardTitle>Review Information</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <p className="text-sm text-gray-500">Review ID</p>
                    <p className="font-mono text-sm">{reviewId}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Submitted At</p>
                    <p className="text-sm">
                      {reviewStatus.submitted_at 
                        ? new Date(reviewStatus.submitted_at).toLocaleString()
                        : 'N/A'}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Reviewed At</p>
                    <p className="text-sm">
                      {reviewStatus.reviewed_at 
                        ? new Date(reviewStatus.reviewed_at).toLocaleString()
                        : 'N/A'}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Domain Scores */}
            {reviewStatus.domain_scores && reviewStatus.domain_scores.length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle>Domain Scores</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4">
                    {reviewStatus.domain_scores.map((score) => (
                      <div key={score.id} className="bg-gray-50 rounded-lg p-4">
                        <div className="flex items-center justify-between mb-2">
                          <span className="text-sm font-medium capitalize">{score.domain}</span>
                          <span className={`text-2xl font-bold ${getScoreColor(score.score)}`}>
                            {score.score}
                          </span>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-2">
                          <div
                            className={`h-2 rounded-full ${score.score >= 4 ? 'bg-green-500' : score.score >= 3 ? 'bg-yellow-500' : 'bg-red-500'}`}
                            style={{ width: `${(score.score / 5) * 100}%` }}
                          ></div>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Findings */}
            {reviewStatus.findings && reviewStatus.findings.length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <AlertTriangle className="w-5 h-5 text-orange-500" />
                    Findings ({reviewStatus.findings?.length || 0})
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {reviewStatus.findings.map((finding) => (
                      <div key={finding.id} className={`border rounded-lg p-4 ${getSeverityColor(finding.severity)}`}>
                        <div className="flex items-start justify-between mb-2">
                          <div className="flex items-center gap-2">
                            <span className="text-xs font-semibold uppercase px-2 py-1 rounded">
                              {finding.severity}
                            </span>
                            <span className="text-sm font-medium capitalize">{finding.domain}</span>
                          </div>
                          {finding.principle_id && (
                            <span className="text-xs text-gray-600">{finding.principle_id}</span>
                          )}
                        </div>
                        <p className="text-sm mb-2">{finding.finding}</p>
                        {finding.recommendation && (
                          <p className="text-sm text-gray-600">
                            <strong>Recommendation:</strong> {finding.recommendation}
                          </p>
                        )}
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            )}

            {/* ADRs */}
            {reviewStatus.adrs && reviewStatus.adrs.length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <FileText className="w-5 h-5 text-blue-500" />
                    Architecture Decision Records ({reviewStatus.adrs?.length || 0})
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {reviewStatus.adrs.map((adr) => (
                      <div key={adr.id} className="border rounded-lg p-4">
                        <div className="flex items-start justify-between mb-2">
                          <span className="font-mono text-sm font-medium">{adr.adr_id}</span>
                          <span className="text-xs px-2 py-1 rounded bg-gray-100 capitalize">
                            {adr.status}
                          </span>
                        </div>
                        <p className="font-medium mb-2">{adr.decision}</p>
                        <p className="text-sm text-gray-600 mb-2">{adr.rationale}</p>
                        {adr.context && (
                          <p className="text-sm text-gray-500 mb-2">
                            <strong>Context:</strong> {adr.context}
                          </p>
                        )}
                        <div className="flex items-center gap-4 text-sm text-gray-500">
                          {adr.owner && (
                            <span><strong>Owner:</strong> {adr.owner}</span>
                          )}
                          {adr.target_date && (
                            <span><strong>Target:</strong> {adr.target_date}</span>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Actions */}
            {reviewStatus.actions && reviewStatus.actions.length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Target className="w-5 h-5 text-purple-500" />
                    Action Items ({reviewStatus.actions?.length || 0})
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {reviewStatus.actions.map((action) => (
                      <div key={action.id} className="border rounded-lg p-4">
                        <div className="flex items-start justify-between mb-2">
                          <p className="font-medium">{action.action_text}</p>
                          <span className="text-xs px-2 py-1 rounded bg-gray-100 capitalize">
                            {action.status}
                          </span>
                        </div>
                        <div className="flex items-center gap-4 text-sm text-gray-500">
                          <span><strong>Owner:</strong> {action.owner_role}</span>
                          {action.due_days && (
                            <span><strong>Due:</strong> {action.due_days} days</span>
                          )}
                          {action.due_date && (
                            <span><strong>Date:</strong> {action.due_date}</span>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Decision */}
            {reviewStatus.decision && (
              <Card>
                <CardHeader>
                  <CardTitle>Review Decision</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className={`p-4 rounded-lg ${
                    reviewStatus.decision === 'approve' ? 'bg-green-50 border-green-200' :
                    reviewStatus.decision === 'reject' ? 'bg-red-50 border-red-200' :
                    reviewStatus.decision === 'defer' ? 'bg-orange-50 border-orange-200' :
                    'bg-yellow-50 border-yellow-200'
                  }`}>
                    <p className="font-semibold text-lg capitalize">{reviewStatus.decision.replace('_', ' ')}</p>
                  </div>
                </CardContent>
              </Card>
            )}

            {/* View Review Button - Only show when status is reviewed */}
            {reviewStatus.status === 'reviewed' && (
              <Card>
                <CardContent>
                  <div className="flex items-center justify-between p-4">
                    <div className="flex items-center gap-2">
                      <CheckCircle className="w-5 h-5 text-green-500" />
                      <span className="font-medium">Review Complete</span>
                    </div>
                    <Button 
                      onClick={() => window.open(`/review/${reviewId}/view`, '_blank')}
                      className="bg-blue-600 hover:bg-blue-700 text-white"
                    >
                      View Full Review
                    </Button>
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Polling Indicator */}
            {polling && (
              <div className="flex items-center justify-center gap-2 text-sm text-gray-500">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-gray-400"></div>
                <span>Updating status...</span>
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  )
}
