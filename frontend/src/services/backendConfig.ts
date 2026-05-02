// Backend Configuration and Abstraction Layer
// This file provides a unified interface that switches between Supabase and Python backends

const BACKEND_TYPE = import.meta.env.VITE_BACKEND_TYPE || 'supabase'

console.log(`Using backend type: ${BACKEND_TYPE}`)

// Import Supabase services
import { metadataService as supabaseMetadataService } from './supabase/metadataService'
import { reviewService as supabaseReviewService } from './supabase/reviewService'
import { supabase } from './supabase/supabase'

// Import Python services
import { metadataService as pythonMetadataService } from './python/metadataService'
import { reviewService as pythonReviewService } from './python/reviewService'
import { api as pythonApi } from './python/api'

// Re-export types from both backends (they should be identical)
export type {
  Step,
  Domain,
  ArtefactType,
  ArtefactTemplate,
  ChecklistSubsection,
  ChecklistQuestion,
  QuestionOption,
  EAPrinciple,
  PrincipleDomain,
  FormField
} from './supabase/metadataService'

export type {
  ReviewData,
  DraftData,
  ReviewResult,
  ReviewStatus,
  ArtefactResponse,
} from './supabase/reviewService'

// Unified metadata service
export const metadataService = BACKEND_TYPE === 'python' 
  ? pythonMetadataService 
  : supabaseMetadataService

// Unified review service
export const reviewService = BACKEND_TYPE === 'python' 
  ? pythonReviewService 
  : supabaseReviewService

// Export backend-specific services for direct access if needed
export const supabaseServices = {
  metadataService: supabaseMetadataService,
  reviewService: supabaseReviewService,
  supabase
}

export const pythonServices = {
  metadataService: pythonMetadataService,
  reviewService: pythonReviewService,
  api: pythonApi
}

// Helper function to check current backend
export const getBackendType = () => BACKEND_TYPE
export const isSupabaseBackend = () => BACKEND_TYPE === 'supabase'
export const isPythonBackend = () => BACKEND_TYPE === 'python'
