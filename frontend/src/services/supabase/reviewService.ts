import { supabase } from './supabase'

// Helper function to ensure Supabase is available
const ensureSupabase = () => {
  if (!supabase) {
    throw new Error('Supabase is not configured. Please set VITE_BACKEND_TYPE=supabase and provide Supabase credentials.')
  }
  return supabase
}

export interface ReviewData {
  solution_name: string
  scope_tags: string[]
  artifact_path: string
  artifact_filename: string
  artifact_file_type: string
  artifact_file_size_bytes?: number
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
  status: 'pending' | 'in_review' | 'submitted' | 'ea_review' | 'approved' | 'rejected' | 'deferred' | 'reviewed'
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
   * Create a new draft review record in Supabase
   */
  async createDraft(data: DraftData) {
    const { data: review, error } = await ensureSupabase()
      .from('reviews')
      .insert({
        solution_name: data.solution_name,
        scope_tags: data.scope_tags,
        artifact_path: '',
        artifact_filename: '',
        artifact_file_type: '',
        sa_user_id: data.sa_user_id,
        status: 'draft',
        report_json: { form_data: data.form_data } // Store form data in report_json for drafts
      })
      .select()
      .single()

    if (error) throw error
    return review
  },

  /**
   * Update an existing draft
   */
  async updateDraft(reviewId: string, data: Partial<DraftData>) {
    const updateData: any = {}
    
    if (data.solution_name) updateData.solution_name = data.solution_name
    if (data.scope_tags) updateData.scope_tags = data.scope_tags
    if (data.status) updateData.status = data.status
    if (data.form_data) {
      // Preserve existing form_data and merge with new data
      const { data: existingReview } = await ensureSupabase()
        .from('reviews')
        .select('report_json')
        .eq('id', reviewId)
        .single()
      
      const existingFormData = existingReview?.report_json?.form_data || {}
      updateData.report_json = { form_data: { ...existingFormData, ...data.form_data } }
    }

    const { data: review, error } = await ensureSupabase()
      .from('reviews')
      .update(updateData)
      .eq('id', reviewId)
      .select()
      .single()

    if (error) throw error
    return review
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
    const { data: review, error } = await ensureSupabase()
      .from('reviews')
      .select('*')
      .eq('id', reviewId)
      .single()

    if (error) throw error

    const missingFields: string[] = []
    const errors: string[] = []

    // Check if artifact is uploaded
    if (!review.artifact_path || review.artifact_path === '') {
      missingFields.push('artifact')
      errors.push('At least one artifact must be uploaded')
    }

    // Check if scope tags are present
    if (!review.scope_tags || review.scope_tags.length === 0) {
      missingFields.push('scope_tags')
      errors.push('At least one domain must be selected')
    }

    // Check form data completeness
    const formData = review.report_json?.form_data || {}
    
    // Check required fields
    if (!formData.project_name) {
      missingFields.push('project_name')
      errors.push('Project name is required')
    }

    // Check domain checklists
    const requiredDomains = ['business', 'application', 'integration', 'data', 'security', 'infrastructure', 'devsecops']
    const domainsWithChecklist = review.scope_tags?.filter((tag: string) => requiredDomains.includes(tag)) || []
    
    for (const domain of domainsWithChecklist) {
      const checklistKey = `${domain}_checklist`
      if (!formData[checklistKey] || Object.keys(formData[checklistKey]).length === 0) {
        missingFields.push(`${domain}_checklist`)
        errors.push(`${domain.charAt(0).toUpperCase() + domain.slice(1)} checklist is incomplete`)
      }
    }

    return {
      isComplete: missingFields.length === 0,
      missingFields,
      errors
    }
  },

  /**
   * Mark review as ready for review and trigger backend
   */
  async markReadyForReview(reviewId: string): Promise<ReviewResult> {
    // First validate completeness
    const validation = await this.validateCompleteness(reviewId)
    
    if (!validation.isComplete) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`)
    }

    // Update status to submitted (this will be the trigger point)
    const { error: updateError } = await ensureSupabase()
      .from('reviews')
      .update({ 
        status: 'submitted',
        submitted_at: new Date().toISOString()
      })
      .eq('id', reviewId)

    if (updateError) throw updateError

    // Trigger the review-orchestrator edge function
    const result = await this.triggerReviewOrchestrator(reviewId)
    
    return result
  },

  /**
   * Create a new review record in Supabase (for direct submission)
   */
  async createReview(data: ReviewData) {
    const { data: review, error } = await ensureSupabase()
      .from('reviews')
      .insert({
        solution_name: data.solution_name,
        scope_tags: data.scope_tags,
        artifact_path: data.artifact_path,
        artifact_filename: data.artifact_filename,
        artifact_file_type: data.artifact_file_type,
        artifact_file_size_bytes: data.artifact_file_size_bytes,
        sa_user_id: data.sa_user_id,
        status: 'pending',
        llm_model: data.llm_model || 'gpt-4o'
      })
      .select()
      .single()

    if (error) throw error
    return review
  },

  /**
   * Upload artifact to Supabase Storage
   */
  async uploadArtifact(reviewId: string, file: File) {
    const filePath = `${reviewId}/${file.name}`
    
    const { data, error } = await ensureSupabase()
      .storage
      .from('review-artifacts')
      .upload(filePath, file, {
        upsert: false,
        contentType: file.type
      })

    if (error) throw error

    return {
      path: data?.path,
      fullPath: `${reviewId}/${file.name}`,
      fileName: file.name,
      fileType: file.type,
      fileSize: file.size
    }
  },

  /**
   * Update review with artifact information
   */
  async updateReviewArtifactInfo(reviewId: string, artifactInfo: {
    artifact_path: string
    artifact_filename: string
    artifact_file_type: string
    artifact_file_size_bytes: number
  }) {
    const { error } = await ensureSupabase()
      .from('reviews')
      .update({
        artifact_path: artifactInfo.artifact_path,
        artifact_filename: artifactInfo.artifact_filename,
        artifact_file_type: artifactInfo.artifact_file_type,
        artifact_file_size_bytes: artifactInfo.artifact_file_size_bytes,
        submitted_at: new Date().toISOString()
      })
      .eq('id', reviewId)

    if (error) throw error
  },

  /**
   * Trigger the review-orchestrator edge function
   */
  async triggerReviewOrchestrator(reviewId: string): Promise<ReviewResult> {
    const { data, error } = await ensureSupabase().functions.invoke('review-orchestrator', {
      body: { reviewId }
    })

    if (error) throw error
    return data as ReviewResult
  },

  /**
   * Get review status and related data
   */
  async getReviewStatus(reviewId: string): Promise<ReviewStatus> {
    const { data: review, error: reviewError } = await ensureSupabase()
      .from('reviews')
      .select('*')
      .eq('id', reviewId)
      .single()

    if (reviewError) throw reviewError

    // Fetch related data in parallel
    const [domainScores, findings, adrs, actions] = await Promise.all([
      ensureSupabase().from('domain_scores').select('*').eq('review_id', reviewId),
      ensureSupabase().from('findings').select('*').eq('review_id', reviewId),
      ensureSupabase().from('adrs').select('*').eq('review_id', reviewId),
      ensureSupabase().from('actions').select('*').eq('review_id', reviewId)
    ])

    return {
      id: review.id,
      status: review.status,
      decision: review.decision,
      report_json: review.report_json,
      domain_scores: domainScores.data || [],
      findings: findings.data || [],
      adrs: adrs.data || [],
      actions: actions.data || [],
      submitted_at: review.submitted_at,
      reviewed_at: review.reviewed_at
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

          // Check if review is complete
          if (status.status === 'ea_review' || 
              status.status === 'approved' || 
              status.status === 'rejected' || 
              status.status === 'deferred') {
            resolve(status)
            return
          }

          // Check if max attempts reached
          if (attempts >= maxAttempts) {
            reject(new Error('Polling timeout: Review did not complete in time'))
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
   * Get all reviews for current user (userId optional for compatibility with Python interface)
   */
  async getUserReviews(userId?: string) {
    const { data: { user: supabaseUser } } = await ensureSupabase().auth.getUser()
    
    const targetUserId = userId || supabaseUser?.id
    
    if (!targetUserId) {
      return []
    }
    
    const { data, error } = await ensureSupabase()
      .from('reviews')
      .select('*')
      .eq('sa_user_id', targetUserId)

    if (error) throw error
    return data
  },

  async getAllReviews() {
    const { data, error } = await ensureSupabase()
      .from('reviews')
      .select('*')

    if (error) throw error
    return data
  },

  /**
   * Get review by ID with full details
   */
  async getReviewById(reviewId: string) {
    const { data, error } = await ensureSupabase()
      .from('reviews')
      .select('*')
      .eq('id', reviewId)
      .single()

    if (error) throw error
    return data
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
   * Extract scope tags from form data and artefacts
   * Maps frontend domain sections and artefact domains to scope tags
   * Uses dynamic domain_data structure and artefact domains
   */
  extractScopeTags(formData: any, artefacts?: Record<string, any[]>): string[] {
    const tags: Set<string> = new Set()
    const VALID_DOMAINS = [
      'general', 'business', 'application', 'integration', 
      'data', 'infrastructure', 'devsecops', 'nfr'
    ]

    // Check for dynamic domain_data structure - add domains with checklist data (new format)
    if (formData.domain_data) {
      Object.keys(formData.domain_data).forEach(domain => {
        // Validate domain name
        if (!VALID_DOMAINS.includes(domain)) {
          console.warn(`Invalid domain '${domain}' found in domain_data, skipping`)
          return
        }

        const domainInfo = formData.domain_data[domain]
        const hasChecklist = domainInfo?.checklist && 
            Object.keys(domainInfo.checklist).length > 0
        const hasEvidence = domainInfo?.evidence && 
            Object.keys(domainInfo.evidence).length > 0
        const hasValidAnswers = hasChecklist && 
            Object.values(domainInfo.checklist).some((answer: any) => 
              answer && ['compliant', 'non_compliant', 'partial', 'na'].includes(answer)
            )

        if (hasChecklist || hasEvidence || hasValidAnswers) {
          tags.add(domain)
        }
      })
    }

    // Check for old format checklist data at root level (backward compatibility)
    Object.keys(formData).forEach(key => {
      if (key.endsWith('_checklist') || key.endsWith('_evidence')) {
        const domain = key.replace(/_(checklist|evidence)$/, '')
        
        // Validate domain name
        if (!VALID_DOMAINS.includes(domain)) {
          console.warn(`Invalid domain '${domain}' found in legacy format, skipping`)
          return
        }

        const data = formData[key]
        if (data && Object.keys(data).length > 0) {
          // For checklist, validate that we have actual compliance answers
          if (key.endsWith('_checklist')) {
            const hasValidAnswers = Object.values(data).some((answer: any) => 
              answer && ['compliant', 'non_compliant', 'partial', 'na'].includes(answer)
            )
            if (hasValidAnswers) {
              tags.add(domain)
            }
          } else {
            // For evidence, any non-empty evidence counts
            tags.add(domain)
          }
        }
      }
    })

    // Add domains from artefacts - if artefacts exist for a domain, include it
    if (artefacts) {
      Object.entries(artefacts).forEach(([domain, domainArtefacts]) => {
        // Validate domain name
        if (!VALID_DOMAINS.includes(domain)) {
          console.warn(`Invalid domain '${domain}' found in artefacts, skipping`)
          return
        }

        if (domainArtefacts && domainArtefacts.length > 0) {
          // Only count domains with successfully uploaded artefacts (have IDs or file data)
          const hasValidArtefacts = domainArtefacts.some((artefact: any) => 
            artefact.id || artefact.file
          )
          if (hasValidArtefacts) {
            tags.add(domain)
          }
        }
      })
    }

    // Special handling for NFR criteria - if any NFR criteria are defined, add 'nfr' tag
    if (formData.nfr_criteria && formData.nfr_criteria.length > 0) {
      const hasValidCriteria = formData.nfr_criteria.some((criterion: any) => 
        criterion.category && criterion.criteria && criterion.target_value
      )
      if (hasValidCriteria) {
        tags.add('nfr')
      }
    }

    // Ensure at least one tag exists for AI review to run
    if (tags.size === 0) {
      console.warn('No valid scope tags found, defaulting to "general"')
      tags.add('general')
    }

    // Sort tags for consistency
    const sortedTags = Array.from(tags).sort()
    
    // Log extraction summary for debugging
    console.log(`Scope tags extracted: [${sortedTags.join(', ')}] from:`, {
      domainDataDomains: Object.keys(formData.domain_data || {}),
      artefactDomains: Object.keys(artefacts || {}),
      nfrCriteriaCount: formData.nfr_criteria?.length || 0
    })

    return sortedTags
  },

  /**
   * Get artifact download URL
   */
  async getArtifactDownloadUrl(reviewId: string, fileName: string) {
    const { data, error } = await ensureSupabase()
      .storage
      .from('review-artifacts')
      .createSignedUrl(`${reviewId}/${fileName}`, 3600) // 1 hour expiry

    if (error) throw error
    return data.signedUrl
  }
}
