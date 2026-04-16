const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

export async function apiRequest(
  endpoint: string,
  options: RequestInit = {}
) {
  const url = `${API_BASE_URL}${endpoint}`
  const token = localStorage.getItem('token')

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  const response = await fetch(url, {
    ...options,
    headers,
  })

  if (!response.ok) {
    throw new Error(`API request failed: ${response.statusText}`)
  }

  return response.json()
}

export const api = {
  // Auth
  login: (email: string, password: string) => {
    const params = new URLSearchParams()
    params.append('username', email)
    params.append('password', password)
    return apiRequest('/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params,
    })
  },

  getDemoUsers: () =>
    apiRequest('/auth/demo-users'),

  // Submissions
  getSubmissions: () =>
    apiRequest('/submissions'),

  getSubmission: (id: string) =>
    apiRequest(`/submissions/${id}`),

  createSubmission: (data: any) =>
    apiRequest('/submissions', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateSubmission: (id: string, data: any) =>
    apiRequest(`/submissions/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  submitSubmission: (id: string) =>
    apiRequest(`/submissions/${id}/submit`, {
      method: 'POST',
    }),

  uploadArtefact: (submissionId: string, file: File) => {
    const formData = new FormData()
    formData.append('file', file)
    return apiRequest(`/submissions/${submissionId}/artefacts`, {
      method: 'POST',
      headers: {}, // Let browser set Content-Type for FormData
      body: formData,
    })
  },

  uploadIntegrationCatalogue: (submissionId: string, file: File) => {
    const formData = new FormData()
    formData.append('file', file)
    return apiRequest(`/submissions/${submissionId}/integration-catalogue`, {
      method: 'POST',
      headers: {},
      body: formData,
    })
  },

  // Reviews
  getReviews: () =>
    apiRequest('/reviews'),

  getReview: (id: string) =>
    apiRequest(`/reviews/${id}`),

  getReviewBySubmission: (submissionId: string) =>
    apiRequest(`/reviews/submission/${submissionId}`),

  createReview: (data: any) =>
    apiRequest('/reviews', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateReview: (id: string, data: any) =>
    apiRequest(`/reviews/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  approveReview: (id: string, overrideRationale?: string) =>
    apiRequest(`/reviews/${id}/approve`, {
      method: 'POST',
      body: JSON.stringify({ override_rationale: overrideRationale }),
    }),

  overrideReview: (id: string, decision: string, rationale: string) =>
    apiRequest(`/reviews/${id}/override`, {
      method: 'POST',
      body: JSON.stringify({ decision, rationale }),
    }),

  // Agent
  runARBReview: (submissionData: any) =>
    apiRequest('/agent/review', {
      method: 'POST',
      body: JSON.stringify(submissionData),
    }),

  populateKnowledgeBase: () =>
    apiRequest('/agent/populate-knowledge-base', {
      method: 'POST',
    }),
}
