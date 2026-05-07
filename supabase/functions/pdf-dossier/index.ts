import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Extract review ID from URL or request body
    const url = new URL(req.url)
    const reviewId = url.searchParams.get('reviewId') || url.pathname.split('/').pop()
    
    if (!reviewId) {
      return new Response(
        JSON.stringify({ error: 'reviewId is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`Generating PDF dossier for reviewId: ${reviewId}`)

    // Supabase client setup
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

    const supabase = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization') ?? '' }
        }
      }
    )

    // Fetch review data
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('*')
      .eq('id', reviewId)
      .single()

    if (reviewError || !review) {
      return new Response(
        JSON.stringify({ error: `Review not found: ${reviewError?.message}` }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch related data for complete dossier
    const [
      { data: domainScores },
      { data: blockers },
      { data: findings },
      { data: actions },
      { data: adrs },
      { data: recommendations },
      { data: nfrScorecard },
      { data: eaReview }
    ] = await Promise.all([
      supabase.from('domain_scores').select('*').eq('review_id', reviewId),
      supabase.from('blockers').select('*').eq('review_id', reviewId),
      supabase.from('findings').select('*').eq('review_id', reviewId),
      supabase.from('actions').select('*').eq('review_id', reviewId),
      supabase.from('adrs').select('*').eq('review_id', reviewId),
      supabase.from('recommendations').select('*').eq('review_id', reviewId),
      supabase.from('nfr_scorecard').select('*').eq('review_id', reviewId),
      supabase.from('ea_review').select('*').eq('review_id', reviewId).single()
    ])

    // Build complete review data structure
    const completeReviewData = {
      id: review.id,
      solution_name: review.solution_name,
      arb_ref: review.arb_ref,
      status: review.status,
      decision: review.decision,
      recommended_decision: review.recommended_decision,
      aggregate_rag_score: review.aggregate_rag_score,
      aggregate_rag_label: review.aggregate_rag_label,
      decision_rationale: review.decision_rationale,
      reviewed_at: review.reviewed_at,
      created_at: review.created_at,
      submitted_at: review.submitted_at,
      ea_review: eaReview,
      domain_summaries: buildDomainSummaries(domainScores || [], findings || [], actions || [], adrs || []),
      blockers: blockers || [],
      actions: actions || [],
      findings: findings || [],
      adrs: adrs || [],
      recommendations: recommendations || [],
      nfr_scorecard: nfrScorecard || [],
      report_json: review.report_json
    }

    // Generate HTML for executive summary
    const htmlContent = generateExecutiveSummaryHTML(completeReviewData)

    // Convert HTML to PDF using external service (since Deno doesn't have direct PDF generation)
    const pdfResponse = await generatePDFFromHTML(htmlContent, review.solution_name || 'dossier')

    if (!pdfResponse.ok) {
      throw new Error(`PDF generation failed: ${pdfResponse.statusText}`)
    }

    const pdfBytes = await pdfResponse.arrayBuffer()

    // Return PDF as streaming response
    const filename = `${(review.solution_name || 'dossier').replace(/[^a-zA-Z0-9]/g, '_')}_ARB_Dossier_${reviewId.slice(0, 8)}.pdf`

    return new Response(pdfBytes, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Content-Length': pdfBytes.byteLength.toString()
      }
    })

  } catch (error) {
    console.error('Error in pdf-dossier function:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

function buildDomainSummaries(domainScores: any[], findings: any[], actions: any[], adrs: any[]) {
  const summaries: Record<string, any> = {}
  
  domainScores.forEach(ds => {
    const domainFindings = findings.filter(f => f.domain === ds.domain)
    const domainActions = actions.filter(a => a.domain === ds.domain)
    const domainADRs = adrs.filter(adr => adr.domain === ds.domain)
    
    summaries[ds.domain] = {
      score: ds.score,
      rag_label: ds.rag_label,
      overall_readiness: ds.overall_readiness,
      executive_summary: ds.executive_summary,
      compliant_areas: ds.compliant_areas || [],
      gap_areas: ds.gap_areas || [],
      blocker_count: ds.blocker_count || 0,
      action_count: ds.action_count || domainActions.length,
      adr_count: ds.adr_count || domainADRs.length,
      findings: domainFindings,
      actions: domainActions,
      adrs: domainADRs
    }
  })
  
  return summaries
}

function generateExecutiveSummaryHTML(reviewData: any): string {
  const {
    solution_name = 'Unknown Solution',
    arb_ref = 'EARR-2026-0412',
    ea_review = {},
    reviewed_at,
    decision = 'pending',
    aggregate_rag_label = 'AMBER',
    decision_rationale = '',
    domain_summaries = {},
    blockers = []
  } = reviewData

  const eaName = ea_review.ea_name || 'Priya Nair'
  const reviewDate = reviewed_at ? new Date(reviewed_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }) : new Date().toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
  
  const decisionMap: Record<string, [string, string]> = {
    'approve': ['Approve', 'rag-g'],
    'approve_with_conditions': ['Approve with conditions', 'rag-a'],
    'conditional_approval': ['Approve with conditions', 'rag-a'],
    'reject': ['Reject', 'rag-r'],
    'defer': ['Defer', 'rag-a'],
    'return': ['Return', 'rag-a'],
    'pending': ['Pending', 'rag-a']
  }
  
  const [decisionText, decisionClass] = decisionMap[decision] || ['Pending', 'rag-a']
  
  const domainStats = Object.values(domain_summaries).reduce((acc: any, domain: any) => {
    const rag = domain.rag_label?.toUpperCase()
    if (rag === 'GREEN') acc.green++
    else if (rag === 'AMBER') acc.amber++
    else if (rag === 'RED') acc.red++
    return acc
  }, { green: 0, amber: 0, red: 0 })
  
  const hasBlocker = blockers.length > 0
  const blockerText = hasBlocker ? `${domainStats.red} domain Red — BLOCKER` : `${domainStats.red} domain Red`
  
  const domainOrder = [
    ['application', 'Application architecture'],
    ['software', 'Software architecture'],
    ['integration', 'Integration architecture'],
    ['api', 'API architecture'],
    ['security', 'Security architecture'],
    ['data', 'Data architecture'],
    ['infrastructure', 'Infra & platform'],
    ['devsecops', 'Engineering & DevSecOps'],
    ['quality', 'Engineering quality']
  ]
  
  const domainRowsHTML = domainOrder.map(([domainKey, domainName]) => {
    const domainData = domain_summaries[domainKey]
    if (!domainData) return ''
    
    const { score = 3, rag_label = 'AMBER', executive_summary = '' } = domainData
    const ragClassMap: Record<string, string> = { 'GREEN': 'rag-g', 'AMBER': 'rag-a', 'RED': 'rag-r' }
    const ragClass = ragClassMap[rag_label] || 'rag-a'
    
    const blockerIndicator = (domainKey === 'security' && hasBlocker) ? '<span class="block-pill">BLOCKER</span>' : ''
    
    return `
    <div class="domain-row">
      <span class="rag-badge ${ragClass}" style="padding:3px 6px;border-radius:4px;font-size:11px">${score}/5</span>
      <span style="color:var(--color-text-primary);font-weight:500">${domainName}${blockerIndicator}</span>
      <span class="rag-badge ${ragClass}">${rag_label}</span>
      <span style="color:var(--color-text-secondary)">${executive_summary}</span>
    </div>`
  }).join('')
  
  const blockerCalloutHTML = hasBlocker ? `
  <!-- Blocker callout -->
  <div style="margin:0 18px 16px;border-radius:var(--border-radius-md);background:#FCEBEB;border:0.5px solid #E24B4A;padding:11px 14px">
    <div style="font-size:11px;font-weight:500;color:#A32D2D;letter-spacing:0.04em;margin-bottom:5px">BLOCKER — MUST RESOLVE BEFORE ARB</div>
    <div style="font-size:13px;color:#501313">${blockers[0]?.blocker_id || 'BLK-01'} · ${blockers[0]?.title || 'Security issue'}.</div>
  </div>` : ''

  return `
<style>
.rag-g{background:#EAF3DE;color:#27500A;border:0.5px solid #97C459}
.rag-a{background:#FAEEDA;color:#633806;border:0.5px solid #EF9F27}
.rag-r{background:#FCEBEB;color:#501313;border:0.5px solid #E24B4A}
.rag-badge{font-size:11px;font-weight:500;padding:2px 8px;border-radius:999px;white-space:nowrap}
.score-pill{display:inline-flex;align-items:center;gap:5px;font-size:12px;padding:4px 10px;border-radius:6px;font-weight:500;border:0.5px solid}
.domain-row{display:grid;grid-template-columns:20px 1fr 80px 1fr;gap:8px 12px;align-items:start;padding:7px 0;border-bottom:0.5px solid #e0e0e0;font-size:13px}
.domain-row:last-child{border-bottom:none}
.block-pill{display:inline-block;font-size:10px;font-weight:500;padding:2px 7px;border-radius:999px;background:#FCEBEB;color:#501313;border:0.5px solid #E24B4A;margin-left:6px}
</style>

<div style="border-radius:8px;border:0.5px solid #ccc;overflow:hidden;font-family:Arial,sans-serif">

  <!-- Header band -->
  <div style="background:#f8f9fa;padding:14px 18px;display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap">
    <div>
      <div style="font-size:11px;color:#666;margin-bottom:3px;letter-spacing:0.04em">PRE-ARB DOSSIER</div>
      <div style="font-size:17px;font-weight:500;color:#333">${solution_name}</div>
      <div style="font-size:12px;color:#666;margin-top:2px">${arb_ref} · EA: ${eaName} · Review: ${reviewDate}</div>
    </div>
    <div style="text-align:right">
      <div style="font-size:11px;color:#666;margin-bottom:5px">RECOMMENDED DECISION</div>
      <span class="score-pill ${decisionClass}" style="font-size:13px;padding:6px 14px">⚠ ${decisionText}</span>
    </div>
  </div>

  <!-- Aggregate bar -->
  <div style="padding:14px 18px;border-bottom:0.5px solid #e0e0e0;display:flex;gap:16px;flex-wrap:wrap;align-items:center">
    <div style="font-size:12px;color:#666">Aggregate readiness</div>
    <div style="display:flex;gap:6px;flex-wrap:wrap">
      <span class="score-pill rag-g">${domainStats.green} domains Green</span>
      <span class="score-pill rag-a">${domainStats.amber} domains Amber</span>
      <span class="score-pill rag-r">${blockerText}</span>
    </div>
  </div>

  <!-- Rationale -->
  <div style="padding:14px 18px;border-bottom:0.5px solid #e0e0e0;font-size:13px;color:#666;line-height:1.7">
    <span style="font-weight:500;color:#333">Agent rationale: </span>
    ${decision_rationale}
  </div>

  <!-- Domain scorecard -->
  <div style="padding:14px 18px">
    <div style="font-size:11px;font-weight:500;color:#666;letter-spacing:0.04em;margin-bottom:8px">DOMAIN SCORECARD</div>

${domainRowsHTML}
  </div>

${blockerCalloutHTML}

</div>
`
}

async function generatePDFFromHTML(htmlContent: string, filename: string): Promise<Response> {
  // Use external PDF generation service
  // This could be a service like HTMLPDF API, or we could use Puppeteer in a separate service
  // For now, we'll use a simple approach with a public API
  
  const pdfServiceUrl = 'https://api.htmlpdf.io/v1/generate'
  
  const response = await fetch(pdfServiceUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${Deno.env.get('HTMLPDF_API_KEY') || ''}`
    },
    body: JSON.stringify({
      html: htmlContent,
      options: {
        format: 'A4',
        margin: {
          top: '2cm',
          right: '2cm',
          bottom: '2cm',
          left: '2cm'
        },
        printBackground: true
      }
    })
  })
  
  return response
}
