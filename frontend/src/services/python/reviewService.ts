import { apiRequest } from './api'
import { artefactService, ArtefactResponse } from './artefactService'

export interface ReviewData {
  solution_name: string
  scope_tags: string[]
  sa_user_id: string
  llm_model?: string
}

export interface DraftData {
  solution_name: string
  scope_tags: string[]
  sa_user_id: string
  form_data?: any
  status?: 'draft' | 'submitted' | 'ready_for_review'
}

export interface ReviewResult {
  success: boolean
  reviewId: string
  report: any
  decision: string
}

export interface ReviewStatus {
  id: string
  status: 'pending' | 'in_review' | 'submitted' | 'ea_review' | 'approved' | 'rejected' | 'deferred'
  decision: string | null
  report_json: any
  domain_scores: any[]
  findings: any[]
  adrs: any[]
  actions: any[]
  submitted_at: string | null
  reviewed_at: string | null
}

export const reviewService = {
  /**
   * Create a new draft review record via Python backend
   */
  async createDraft(data: DraftData) {
    return await apiRequest('/reviews', {
      method: 'POST',
      body: JSON.stringify({
        solution_name: data.solution_name,
        scope_tags: data.scope_tags,
        sa_user_id: data.sa_user_id,
        status: 'draft',
        report_json: { form_data: data.form_data }
      })
    })
  },

  /**
   * Update an existing draft via Python backend
   */
  async updateDraft(reviewId: string, data: Partial<DraftData>) {
    return await apiRequest(`/reviews/${reviewId}`, {
      method: 'PUT',
      body: JSON.stringify(data)
    })
  },

  /**
   * Validate submission completeness
   * Returns validation result with missing fields
   */
  async validateCompleteness(reviewId: string): Promise<{
    isComplete: boolean
    missingFields: string[]
    errors: string[]
  }> {
    // For now, return basic validation
    // This should be implemented in Python backend
    return {
      isComplete: true,
      missingFields: [],
      errors: []
    }
  },

  /**
   * Mark review as ready for review and trigger backend
   */
  async markReadyForReview(reviewId: string): Promise<ReviewResult> {
    // Update status to submitted
    await apiRequest(`/reviews/${reviewId}`, {
      method: 'PUT',
      body: JSON.stringify({ status: 'submitted' })
    })

    // Trigger review orchestrator
    const result = await this.triggerReviewOrchestrator(reviewId)
    
    return result
  },

  /**
   * Create a new review record via Python backend
   */
  async createReview(data: ReviewData) {
    return await apiRequest('/reviews', {
      method: 'POST',
      body: JSON.stringify(data)
    })
  },

  /**
   * Upload a single artifact (for compatibility with Supabase interface)
   */
  async uploadArtifact(reviewId: string, file: File) {
    const result = await artefactService.uploadArtefact({
      review_id: reviewId,
      domain_slug: 'general',
      artefact_name: file.name,
      artefact_type: file.type,
      file
    })
    // Transform to match Supabase return structure
    return {
      path: result.filename,
      fullPath: `${reviewId}/${result.filename}`,
      fileName: result.filename,
      fileType: result.file_type || file.type,
      fileSize: result.file_size_bytes || file.size
    }
  },

  /**
   * Upload artefacts using the new artefact service
   */
  async uploadArtefacts(reviewId: string, artefacts: {
    domain: string
    name: string
    type: string
    file: File
  }[]): Promise<ArtefactResponse[]> {
    return await artefactService.uploadMultipleArtefacts(reviewId, artefacts)
  },

  /**
   * Update review with artifact information (for compatibility with Supabase interface)
   */
  async updateReviewArtifactInfo(reviewId: string, artifactInfo: {
    artifact_path: string
    artifact_filename: string
    artifact_file_type: string
    artifact_file_size_bytes: number
  }) {
    return await apiRequest(`/reviews/${reviewId}`, {
      method: 'PUT',
      body: JSON.stringify(artifactInfo)
    })
  },

  /**
   * Get artefacts for a review
   */
  async getReviewArtefacts(reviewId: string): Promise<ArtefactResponse[]> {
    return await artefactService.getReviewArtefacts(reviewId)
  },

  /**
   * Trigger the review orchestrator via Python backend
   */
  async triggerReviewOrchestrator(reviewId: string): Promise<ReviewResult> {
    return await apiRequest('/agent/review', {
      method: 'POST',
      body: JSON.stringify({ reviewId })
    })
  },

  /**
   * Get review status and related data via Python backend
   */
  async getReviewStatus(reviewId: string): Promise<ReviewStatus> {
    const data = await apiRequest(`/reviews/${reviewId}`)
    
    // Backend now returns related data directly
    return {
      id: data.id,
      status: data.status,
      decision: data.decision,
      report_json: data.report_json,
      domain_scores: data.domain_scores || [],
      findings: data.findings || [],
      adrs: data.adrs || [],
      actions: data.actions || [],
      submitted_at: data.submitted_at,
      reviewed_at: data.reviewed_at
    }
  },

  /**
   * Poll for review status updates
   */
  async pollReviewStatus(
    reviewId: string,
    onUpdate: (status: ReviewStatus) => void,
    intervalMs: number = 5000,
    maxAttempts: number = 60
  ): Promise<ReviewStatus> {
    let attempts = 0

    return new Promise((resolve, reject) => {
      const poll = async () => {
        attempts++
        
        try {
          const status = await this.getReviewStatus(reviewId)
          onUpdate(status)
          
          // If review is complete, resolve
          if (status.status === 'approved' || status.status === 'rejected' || 
              status.status === 'deferred') {
            resolve(status)
            return
          }
          
          // If max attempts reached, resolve with current status
          if (attempts >= maxAttempts) {
            resolve(status)
            return
          }
          
          // Continue polling
          setTimeout(poll, intervalMs)
        } catch (error) {
          reject(error)
        }
      }
      
      poll()
    })
  },

  /**
   * Get reviews by user (userId optional for compatibility with Supabase interface)
   */
  async getUserReviews(userId?: string) {
    if (userId) {
      return await apiRequest(`/reviews?user_id=${userId}`)
    }
    // If no userId provided, get all reviews (backend should filter by auth token)
    return await apiRequest('/reviews')
  },

  async getAllReviews() {
    return await apiRequest('/reviews')
  },

  /**
   * Get review by ID with full details via Python backend
   */
  async getReviewById(reviewId: string) {
    return await apiRequest(`/reviews/${reviewId}`)
  },

  /**
   * Load draft data for editing
   */
  async loadDraftData(reviewId: string) {
    const review = await this.getReviewById(reviewId)
    return {
      review,
      formData: review.report_json?.form_data || {}
    }
  },

  /**
   * Extract scope tags from form data
   * Maps frontend domain sections to scope tags
   * Uses dynamic domain_data structure
   */
  extractScopeTags(formData: any): string[] {
    const tags: string[] = []

    // Check for dynamic domain_data structure
    if (formData.domain_data) {
      Object.keys(formData.domain_data).forEach(domain => {
        if (formData.domain_data[domain].checklist && 
            Object.keys(formData.domain_data[domain].checklist).length > 0) {
          tags.push(domain)
        }
      })
    }

    return tags
  },

  /**
   * Get artifact download URL via Python backend
   */
  async getArtifactDownloadUrl(reviewId: string, fileName: string) {
    // This should be implemented in Python backend
    // For now, return a placeholder
    return `${import.meta.env.VITE_API_BASE_URL || '/api/v1'}/reviews/${reviewId}/artifact/${fileName}`
  }
}
