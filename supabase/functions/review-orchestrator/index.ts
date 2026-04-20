import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { OrchestratorAgent } from "./agents/orchestrator.ts"
import { GeneralDomainAgent } from "./agents/general.ts"
import { BusinessDomainAgent } from "./agents/business.ts"
import { ApplicationDomainAgent } from "./agents/application.ts"
import { IntegrationDomainAgent } from "./agents/integration.ts"
import { DataDomainAgent } from "./agents/data.ts"
import { SecurityDomainAgent } from "./agents/security.ts"
import { InfrastructureDomainAgent } from "./agents/infrastructure.ts"
import { DevSecOpsDomainAgent } from "./agents/devsecops.ts"
import { NFRAgent } from "./agents/nfr.ts"
import { extractTextFromArtifact } from "./utils/text-extraction.ts"
import { callLLM } from "./utils/llm.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { reviewId } = await req.json()
    
    if (!reviewId) {
      throw new Error('reviewId is required')
    }

    const supabase = createClient(
      Deno.env.get('PROJECT_URL') ?? '',
      Deno.env.get('SERVICE_ROLE_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization') ?? '' }
        }
      }
    )

    console.log(`Starting review processing for reviewId: ${reviewId}`)

    // ============================================================================
    // STEP 1: Fetch review and validate
    // ============================================================================
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('*')
      .eq('id', reviewId)
      .single()

    if (reviewError || !review) {
      throw new Error(`Review not found: ${reviewError?.message}`)
    }

    if (review.status !== 'pending') {
      throw new Error(`Review already processed: ${review.status}`)
    }

    // Update status to in_review
    await supabase
      .from('reviews')
      .update({ 
        status: 'in_review',
        submitted_at: new Date().toISOString()
      })
      .eq('id', reviewId)

    console.log(`Review ${reviewId} status updated to in_review`)

    // ============================================================================
    // STEP 2: Load MD files based on scope tags
    // ============================================================================
    const { data: mdFiles } = await supabase
      .from('md_files')
      .select('*')
      .contains('domain_tags', review.scope_tags)
      .eq('is_active', true)
      .order('priority', { ascending: true })

    if (!mdFiles || mdFiles.length === 0) {
      throw new Error('No MD files found for the given scope')
    }

    const totalTokens = mdFiles.reduce((sum, file) => sum + (file.token_estimate || 0), 0)
    console.log(`Loaded ${mdFiles.length} MD files, estimated ${totalTokens} tokens`)

    // Concatenate MD content into system prompt
    const knowledgeBase = mdFiles
      .map(file => `## ${file.filename}\n\n${file.content}`)
      .join('\n\n---\n\n')

    // ============================================================================
    // STEP 3: Parse artifact from Storage
    // ============================================================================
    console.log(`Downloading artifact from: ${review.artifact_path}`)
    const { data: artifactData, error: downloadError } = await supabase
      .storage
      .from('review-artifacts')
      .download(review.artifact_path)

    if (downloadError || !artifactData) {
      throw new Error(`Failed to download artifact: ${downloadError?.message}`)
    }

    const artifactText = await extractTextFromArtifact(
      artifactData,
      review.artifact_file_type || 'pdf'
    )
    console.log(`Extracted ${artifactText.length} characters from artifact`)

    // ============================================================================
    // STEP 4: Initialize domain agents
    // ============================================================================
    const domainAgents = {
      general: new GeneralDomainAgent(),
      business: new BusinessDomainAgent(),
      application: new ApplicationDomainAgent(),
      integration: new IntegrationDomainAgent(),
      data: new DataDomainAgent(),
      security: new SecurityDomainAgent(),
      infrastructure: new InfrastructureDomainAgent(),
      devsecops: new DevSecOpsDomainAgent(),
      nfr: new NFRAgent()
    }

    // ============================================================================
    // STEP 5: Run orchestrator with domain agents
    // ============================================================================
    const orchestrator = new OrchestratorAgent()
    const startTime = Date.now()

    const reviewResult = await orchestrator.validateReview({
      review,
      artifactText,
      knowledgeBase,
      domainAgents,
      scopeTags: review.scope_tags
    })

    const processingTime = Date.now() - startTime
    console.log(`Review processing completed in ${processingTime}ms`)

    // ============================================================================
    // STEP 6: Store results in database
    // ============================================================================
    
    // Update reviews table
    const { error: updateError } = await supabase
      .from('reviews')
      .update({
        status: 'ea_review',
        decision: reviewResult.decision,
        report_json: reviewResult.fullReport,
        tokens_used: reviewResult.tokensUsed,
        processing_time_ms: processingTime,
        llm_raw_response: reviewResult.rawResponse,
        reviewed_at: new Date().toISOString()
      })
      .eq('id', reviewId)

    if (updateError) throw updateError

    // Insert domain scores
    for (const [domain, score] of Object.entries(reviewResult.domainScores || {})) {
      await supabase.from('domain_scores').insert({
        review_id: reviewId,
        domain,
        score
      })
    }

    // Insert findings
    if (reviewResult.findings && Array.isArray(reviewResult.findings)) {
      for (const finding of reviewResult.findings) {
        await supabase.from('findings').insert({
          review_id: reviewId,
          domain: finding.domain,
          principle_id: finding.principle_id,
          severity: finding.severity,
          finding: finding.finding,
          recommendation: finding.recommendation
        })
      }
    }

    // Insert ADRs
    if (reviewResult.adrs && Array.isArray(reviewResult.adrs)) {
      for (const adr of reviewResult.adrs) {
        await supabase.from('adrs').insert({
          review_id: reviewId,
          adr_id: adr.id,
          decision: adr.decision,
          rationale: adr.rationale,
          owner: adr.owner,
          target_date: adr.target_date
        })
      }
    }

    // Insert actions
    if (reviewResult.actions && Array.isArray(reviewResult.actions)) {
      for (const action of reviewResult.actions) {
        const dueDate = action.due_days 
          ? new Date(Date.now() + action.due_days * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
          : null
        
        await supabase.from('actions').insert({
          review_id: reviewId,
          action_text: action.action,
          owner_role: action.owner_role,
          due_days: action.due_days,
          due_date: dueDate
        })
      }
    }

    // Log completion
    await supabase.from('audit_log').insert({
      review_id: reviewId,
      user_id: null,
      user_role: 'system',
      action: 'llm_processed',
      metadata: {
        tokens_used: reviewResult.tokensUsed,
        processing_time_ms: processingTime,
        model: review.llm_model || 'gpt-4o',
        domains_reviewed: review.scope_tags
      }
    })

    console.log(`Review ${reviewId} processing completed successfully`)

    return new Response(
      JSON.stringify({ 
        success: true, 
        reviewId, 
        report: reviewResult.fullReport,
        decision: reviewResult.decision
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in review-orchestrator:', error)
    
    // Log error if we have reviewId
    if (typeof reviewId !== 'undefined') {
      try {
        await supabase?.from('audit_log').insert({
          review_id: reviewId,
          user_id: null,
          user_role: 'system',
          action: 'processing_error',
          metadata: { error: error.message }
        })
      } catch (logError) {
        console.error('Failed to log error:', logError)
      }
    }

    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
