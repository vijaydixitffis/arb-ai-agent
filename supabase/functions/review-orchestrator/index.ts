import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { OrchestratorAgent } from "./agents/orchestrator.ts"
import { extractTextFromArtifact } from "./utils/text-extraction.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Declare outside try so the catch block can reference them for audit logging.
  let reviewId: string | undefined
  const supabase = createClient(
    Deno.env.get('PROJECT_URL') ?? '',
    Deno.env.get('SERVICE_ROLE_KEY') ?? '',
    {
      global: {
        headers: { Authorization: req.headers.get('Authorization') ?? '' }
      }
    }
  )

  try {
    const body = await req.json()
    reviewId = body.reviewId

    if (!reviewId) throw new Error('reviewId is required')

    console.log(`Starting review processing for reviewId: ${reviewId}`)

    // ── STEP 1: Fetch review and validate ─────────────────────────────────────
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('*')
      .eq('id', reviewId)
      .single()

    if (reviewError || !review) {
      throw new Error(`Review not found: ${reviewError?.message}`)
    }

    // Accept 'pending' or 'submitted' — frontend sets 'submitted' before triggering
    if (!['pending', 'submitted'].includes(review.status)) {
      throw new Error(`Review already processed: ${review.status}`)
    }

    await supabase
      .from('reviews')
      .update({ status: 'in_review', submitted_at: new Date().toISOString() })
      .eq('id', reviewId)

    console.log(`Review ${reviewId} status updated to in_review`)

    // ── STEP 2: Extract artifact text (optional — new schema stores in artefact_uploads) ──
    let artifactText = ''
    if (review.artifact_path) {
      console.log(`Downloading artifact from: ${review.artifact_path}`)
      const { data: artifactData, error: downloadError } = await supabase
        .storage
        .from('review-artifacts')
        .download(review.artifact_path)

      if (downloadError || !artifactData) {
        console.warn(`Artifact download failed (non-fatal): ${downloadError?.message}`)
      } else {
        artifactText = await extractTextFromArtifact(
          artifactData,
          review.artifact_file_type || 'pdf'
        )
        console.log(`Extracted ${artifactText.length} characters from artifact`)
      }
    }

    // ── STEP 3: Run orchestrator ───────────────────────────────────────────────
    const orchestrator = new OrchestratorAgent()
    const startTime    = Date.now()

    const reviewResult = await orchestrator.validateReview({
      review,
      reportJson:   review.report_json,
      artifactText,
      supabase,
      scopeTags:    review.scope_tags ?? [],
    })

    const processingTime = Date.now() - startTime
    console.log(`Review processing completed in ${processingTime}ms`)

    // ── STEP 4: Persist results ────────────────────────────────────────────────

    // 4a. Update reviews table (fullReport already merges form_data + ai_review)
    const { error: updateError } = await supabase
      .from('reviews')
      .update({
        status:             'ea_review',
        decision:           reviewResult.decision,
        report_json:        reviewResult.fullReport,
        tokens_used:        reviewResult.tokensUsed,
        processing_time_ms: processingTime,
        llm_raw_response:   reviewResult.rawResponse,
        reviewed_at:        new Date().toISOString(),
      })
      .eq('id', reviewId)

    if (updateError) throw updateError

    // 4b. Domain scores (upsert to handle re-runs)
    for (const [domain, score] of Object.entries(reviewResult.domainScores)) {
      const { error: dsErr } = await supabase
        .from('domain_scores')
        .upsert(
          { review_id: reviewId, domain, score },
          { onConflict: 'review_id,domain' }
        )
      if (dsErr) console.error(`domain_scores upsert failed for ${domain}:`, dsErr.message)
    }

    // 4c. Findings — delete old then insert fresh (avoids duplicates on re-run)
    await supabase.from('findings').delete().eq('review_id', reviewId)
    if (reviewResult.findings.length > 0) {
      const { error: findErr } = await supabase
        .from('findings')
        .insert(
          reviewResult.findings.map(f => ({
            review_id:      reviewId,
            domain:         f.domain,
            principle_id:   f.principle_id   || null,
            severity:       f.severity,        // critical | major | minor (DB constraint)
            finding:        f.finding,
            recommendation: f.recommendation || null,
            is_resolved:    false,
          }))
        )
      if (findErr) console.error('findings insert failed:', findErr.message)
    }

    // 4d. ADRs
    if (reviewResult.adrs.length > 0) {
      const { error: adrErr } = await supabase
        .from('adrs')
        .insert(
          reviewResult.adrs.map((adr, i) => {
            const adrId = adr.id || `ADR-${reviewId.slice(0, 8)}-${String(i + 1).padStart(3, '0')}`
            const consequences = (adr.type === 'WAIVER' && adr.waiver_expiry_date)
              ? `waiver_expiry_date: ${adr.waiver_expiry_date}`
              : null
            return {
              review_id:    reviewId,
              adr_id:       adrId,
              decision:     adr.decision,
              rationale:    adr.rationale,
              context:      adr.context      ?? null,
              consequences: consequences,
              owner:        adr.owner        ?? null,
              target_date:  adr.target_date  ?? null,
              status:       'proposed',       // DB constraint: proposed | accepted | rejected | superseded
            }
          })
        )
      if (adrErr) console.error('adrs insert failed:', adrErr.message)
    }

    // 4e. Actions
    if (reviewResult.actions.length > 0) {
      const { error: actErr } = await supabase
        .from('actions')
        .insert(
          reviewResult.actions.map(action => {
            const dueDays = action.due_days != null ? parseInt(String(action.due_days), 10) || null : null
            const dueDate = dueDays
              ? new Date(Date.now() + dueDays * 86_400_000).toISOString().split('T')[0]
              : null
            return {
              review_id:   reviewId,
              action_text: action.action,
              owner_role:  action.owner_role,
              due_days:    dueDays,
              due_date:    dueDate,
              status:      'open',            // DB constraint: open | in_progress | completed | blocked
            }
          })
        )
      if (actErr) console.error('actions insert failed:', actErr.message)
    }

    // 4f. Audit log
    await supabase.from('audit_log').insert({
      review_id: reviewId,
      user_id:   null,
      user_role: 'system',
      action:    'llm_processed',
      metadata: {
        tokens_used:       reviewResult.tokensUsed,
        processing_time_ms: processingTime,
        model:             review.llm_model || Deno.env.get('GEMINI_MODEL') || 'gemini-2.5-flash-lite',
        domains_reviewed:  review.scope_tags,
        findings_count:    reviewResult.findings.length,
        adrs_count:        reviewResult.adrs.length,
        actions_count:     reviewResult.actions.length,
      },
    })

    console.log(`Review ${reviewId} processing completed successfully`)

    return new Response(
      JSON.stringify({
        success:  true,
        reviewId,
        decision: reviewResult.decision,
        report:   reviewResult.fullReport,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in review-orchestrator:', error)

    if (reviewId) {
      try {
        await supabase.from('audit_log').insert({
          review_id: reviewId,
          user_id:   null,
          user_role: 'system',
          action:    'processing_error',
          metadata:  { error: error.message },
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
