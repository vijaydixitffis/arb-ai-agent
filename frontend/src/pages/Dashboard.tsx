import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'
import { Button } from '../components/ui/Button'
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card'
import { FileText, Plus, Eye, CheckCircle, Clock, CheckCircle2, XCircle } from 'lucide-react'
import { api } from '../services/api'

export default function Dashboard() {
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const [submissions, setSubmissions] = useState<any[]>([])
  const [reviews, setReviews] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [ptxGate, setPtxGate] = useState('')
  const [architectureDisposition, setArchitectureDisposition] = useState('')

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      const token = localStorage.getItem('token')
      if (!token) return

      const isSolutionArchitect = user?.role === 'solution_architect'
      const isEnterpriseArchitect = user?.role === 'enterprise_architect' || user?.role === 'arb_admin'

      if (isSolutionArchitect) {
        const subs = await api.getSubmissions()
        setSubmissions(subs)
      }

      if (isEnterpriseArchitect) {
        const revs = await api.getReviews()
        setReviews(revs)
      }
    } catch (error) {
      console.error('Error fetching data:', error)
      // Use mock data on error
      setSubmissions([
        {
          id: 'arb-20240409001',
          project_name: 'Customer 360 Platform',
          status: 'submitted',
          created_date: '2024-04-09',
          overall_progress: 100,
        },
        {
          id: 'arb-20240409002',
          project_name: 'E-commerce Microservices',
          status: 'approved',
          created_date: '2024-04-08',
          overall_progress: 100,
        },
        {
          id: 'arb-20240409003',
          project_name: 'Data Lake Migration',
          status: 'draft',
          created_date: '2024-04-10',
          overall_progress: 45,
        },
      ])
      setReviews([
        {
          id: 'review-20240409001',
          submission_id: 'arb-20240409001',
          project_name: 'Customer 360 Platform',
          status: 'pending',
          agent_recommendation: 'APPROVE_WITH_ACTIONS',
        },
        {
          id: 'review-20240409002',
          submission_id: 'arb-20240409004',
          project_name: 'API Gateway Implementation',
          status: 'pending',
          agent_recommendation: 'DEFER',
        },
      ])
    } finally {
      setLoading(false)
    }
  }

  const isSolutionArchitect = user?.role === 'solution_architect'
  const isEnterpriseArchitect = user?.role === 'enterprise_architect' || user?.role === 'arb_admin'

  // Calculate statistics
  const totalSubmissions = submissions.length
  const pendingReviews = reviews.filter(r => r.status === 'pending').length
  const approved = submissions.filter(s => s.status === 'approved').length
  const rejected = submissions.filter(s => s.status === 'rejected').length

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Dashboard</h1>
        <p className="text-gray-600">
          {isSolutionArchitect
            ? 'Overview of your ARB submissions'
            : 'Overview of ARB reviews'}
        </p>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 mb-1">Total Submissions</p>
                <p className="text-3xl font-bold">{totalSubmissions}</p>
              </div>
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <FileText className="w-6 h-6 text-blue-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        {isEnterpriseArchitect && (
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600 mb-1">Pending Reviews</p>
                  <p className="text-3xl font-bold">{pendingReviews}</p>
                </div>
                <div className="w-12 h-12 bg-amber-100 rounded-lg flex items-center justify-center">
                  <Clock className="w-6 h-6 text-amber-600" />
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 mb-1">Approved</p>
                <p className="text-3xl font-bold">{approved}</p>
              </div>
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <CheckCircle2 className="w-6 h-6 text-green-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 mb-1">Rejected</p>
                <p className="text-3xl font-bold">{rejected}</p>
              </div>
              <div className="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                <XCircle className="w-6 h-6 text-red-600" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {isSolutionArchitect && (
        <div className="mb-8">
          <Button onClick={() => setIsModalOpen(true)} className="flex items-center gap-2">
            <Plus className="w-4 h-4" />
            New EA Review Request
          </Button>
        </div>
      )}

      <div className="grid gap-6">
        {loading ? (
          <Card>
            <CardContent className="p-6">
              <p className="text-center text-gray-600">Loading...</p>
            </CardContent>
          </Card>
        ) : isSolutionArchitect && (
          <Card>
            <CardHeader>
              <CardTitle>Recent Submissions</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Project Name</th>
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Status</th>
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Submitted Date</th>
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {submissions.map((submission) => (
                      <tr key={submission.id} className="border-b hover:bg-gray-50">
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-3">
                            <FileText className="w-4 h-4 text-gray-500" />
                            <div>
                              <p className="font-medium">{submission.project_name}</p>
                              <p className="text-sm text-gray-500">{submission.id}</p>
                            </div>
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          <span className={`text-sm px-2 py-1 rounded ${
                            submission.status === 'approved' ? 'bg-green-100 text-green-800' :
                            submission.status === 'submitted' ? 'bg-blue-100 text-blue-800' :
                            submission.status === 'draft' ? 'bg-gray-100 text-gray-800' :
                            'bg-red-100 text-red-800'
                          }`}>
                            {submission.status}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-sm text-gray-600">{submission.created_date}</td>
                        <td className="py-3 px-4">
                          <Button variant="ghost" size="sm">
                            <Eye className="w-4 h-4" />
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        )}

        {isEnterpriseArchitect && (
          <Card>
            <CardHeader>
              <CardTitle>Pending Reviews</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Project Name</th>
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Submission ID</th>
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Agent Recommendation</th>
                      <th className="text-left py-3 px-4 text-sm font-medium text-gray-600">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {reviews.map((review) => (
                      <tr key={review.id} className="border-b hover:bg-gray-50">
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-3">
                            <CheckCircle className="w-4 h-4 text-gray-500" />
                            <p className="font-medium">{review.project_name}</p>
                          </div>
                        </td>
                        <td className="py-3 px-4 text-sm text-gray-600">{review.submission_id}</td>
                        <td className="py-3 px-4">
                          <span className="text-sm px-2 py-1 rounded bg-amber-100 text-amber-800">
                            {review.agent_recommendation}
                          </span>
                        </td>
                        <td className="py-3 px-4">
                          <Button
                            onClick={() => navigate(`/review/${review.submission_id}`)}
                            size="sm"
                          >
                            Review
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Modal for New EA Review Request */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold">New EA Review Request</h3>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                ✕
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-2">PTX Gate</label>
                <select
                  className="w-full px-3 py-2 border rounded-md"
                  value={ptxGate}
                  onChange={(e) => setPtxGate(e.target.value)}
                >
                  <option value="">Select PTX Gate</option>
                  <option value="Permit to Evaluate">Permit to Evaluate</option>
                  <option value="Permit to Purchase">Permit to Purchase</option>
                  <option value="Permit to Design">Permit to Design</option>
                  <option value="Permit to Build">Permit to Build</option>
                  <option value="Permit to Operate">Permit to Operate</option>
                  <option value="Permit to Retire">Permit to Retire</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Architecture Disposition</label>
                <select
                  className="w-full px-3 py-2 border rounded-md"
                  value={architectureDisposition}
                  onChange={(e) => setArchitectureDisposition(e.target.value)}
                >
                  <option value="">Select Architecture Disposition</option>
                  <option value="Architecture Pattern Review">Architecture Pattern Review</option>
                  <option value="High Bar Review">High Bar Review</option>
                  <option value="Architecture Review Board">Architecture Review Board</option>
                  <option value="Change Acceptance Board">Change Acceptance Board</option>
                  <option value="FastPath">FastPath</option>
                </select>
              </div>
              <Button
                onClick={() => {
                  if (ptxGate && architectureDisposition) {
                    setIsModalOpen(false)
                    navigate('/submission/new', { state: { ptxGate, architectureDisposition } })
                  }
                }}
                className="w-full"
                disabled={!ptxGate || !architectureDisposition}
              >
                Create Request
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
