import React, { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import {
  ChevronLeft, X, CheckCircle, XCircle, AlertCircle, Clock,
  AlertTriangle, Shield, Database, Server, Code, GitMerge,
  Layers, Activity, Briefcase, ChevronRight, FileText, Zap,
} from 'lucide-react'
import { Button } from '../components/ui/Button'
import { Textarea } from '../components/ui/Textarea'
import { reviewService } from '../services/backendConfig'

// ── Domain metadata ──────────────────────────────────────────────────────────

const DOMAIN_META: Record<string, { label: string; Icon: React.ElementType }> = {
  general:        { label: 'General Architecture',       Icon: Layers },
  business:       { label: 'Business Domain',            Icon: Briefcase },
  application:    { label: 'Application Domain',         Icon: Code },
  integration:    { label: 'Integration Domain',         Icon: GitMerge },
  data:           { label: 'Data Domain',                Icon: Database },
  infrastructure: { label: 'Infrastructure & Platform',  Icon: Server },
  devsecops:      { label: 'DevSecOps',                  Icon: Shield },
  nfr:            { label: 'Non-Functional Requirements', Icon: Activity },
  security:       { label: 'Security Domain',            Icon: Shield },
}

const DOMAIN_ORDER = ['general', 'business', 'application', 'integration', 'data', 'infrastructure', 'devsecops', 'nfr', 'security']

// ── RAG helpers ───────────────────────────────────────────────────────────────

interface RagStyle { bg: string; text: string; border: string; dot: string; pill: string }

function ragStyle(score: number): RagStyle {
  if (score <= 2) return {
    bg: 'bg-red-50', text: 'text-red-800', border: 'border-red-200',
    dot: 'bg-red-500', pill: 'bg-red-100 text-red-800',
  }
  if (score === 3) return {
    bg: 'bg-amber-50', text: 'text-amber-800', border: 'border-amber-200',
    dot: 'bg-amber-500', pill: 'bg-amber-100 text-amber-800',
  }
  return {
    bg: 'bg-green-50', text: 'text-green-800', border: 'border-green-200',
    dot: 'bg-green-500', pill: 'bg-green-100 text-green-800',
  }
}

function ragLabelFromScore(score: number): string {
  if (score <= 2) return 'RED'
  if (score === 3) return 'AMBER'
  return 'GREEN'
}

const DECISION_META: Record<string, { label: string; color: string; Icon: React.ElementType }> = {
  approve:                  { label: 'Approve',                  color: 'bg-green-100 text-green-800', Icon: CheckCircle },
  approve_with_conditions:  { label: 'Approve with Conditions',  color: 'bg-amber-100 text-amber-800', Icon: AlertCircle },
  defer:                    { label: 'Defer',                    color: 'bg-orange-100 text-orange-800', Icon: Clock },
  reject:                   { label: 'Reject',                   color: 'bg-red-100 text-red-800',    Icon: XCircle },
}

function decisionMeta(decision: string | null | undefined) {
  const key = (decision || '').toLowerCase().replace(/ /g, '_')
  return DECISION_META[key] || { label: decision || 'Pending', color: 'bg-gray-100 text-gray-700', Icon: Clock }
}

// ── Severity badge ────────────────────────────────────────────────────────────

function SeverityBadge({ severity, ragScore }: { severity?: string; ragScore?: number }) {
  const score = ragScore ?? 3
  const label = score <= 1 ? 'Blocker' : score === 2 ? 'Critical' : score === 3 ? 'Major' : 'Minor'
  const cls   = score <= 1 ? 'bg-red-600 text-white'
              : score === 2 ? 'bg-red-100 text-red-800'
              : score === 3 ? 'bg-amber-100 text-amber-800'
              : 'bg-gray-100 text-gray-700'
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold ${cls}`}>
      {label}
    </span>
  )
}

// ── Domain Detail Panel ───────────────────────────────────────────────────────

interface DomainSummary {
  score: number
  rag_label: string
  total_findings: number
  blocker_count: number
  critical_count: number
  action_count: number
  adr_count: number
  findings: any[]
  actions: any[]
  adrs: any[]
  recommendations: any[]
}

function DomainDetailPanel({
  slug,
  summary,
  onClose,
}: {
  slug: string
  summary: DomainSummary
  onClose: () => void
}) {
  const meta  = DOMAIN_META[slug] || { label: slug, Icon: FileText }
  const style = ragStyle(summary.score)
  const Icon  = meta.Icon

  return (
    <div className="fixed inset-0 z-40 flex justify-end" onClick={onClose}>
      <div
        className="w-full max-w-2xl h-full bg-white shadow-2xl flex flex-col"
        onClick={e => e.stopPropagation()}
      >
        {/* Panel header */}
        <div className={`flex items-center justify-between px-6 py-4 border-b ${style.bg} ${style.border} border-b`}>
          <div className="flex items-center gap-3">
            <div className={`p-2 rounded-lg ${style.pill}`}>
              <Icon className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold">{meta.label}</h2>
              <div className="flex items-center gap-2 mt-0.5">
                <span className={`w-2 h-2 rounded-full ${style.dot}`} />
                <span className={`text-xs font-semibold ${style.text}`}>
                  {summary.rag_label} — Score {summary.score}/5
                </span>
              </div>
            </div>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-white/60 rounded-lg transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Panel body — scrollable */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">

          {/* Stats row */}
          <div className="grid grid-cols-4 gap-3">
            {[
              { label: 'Findings',  value: summary.total_findings },
              { label: 'Blockers',  value: summary.blocker_count,  red: true },
              { label: 'Actions',   value: summary.action_count },
              { label: 'ADRs',      value: summary.adr_count },
            ].map(s => (
              <div key={s.label} className={`rounded-lg p-3 text-center border ${s.red && s.value > 0 ? 'border-red-200 bg-red-50' : 'border-gray-100 bg-gray-50'}`}>
                <div className={`text-2xl font-bold ${s.red && s.value > 0 ? 'text-red-700' : 'text-gray-800'}`}>{s.value}</div>
                <div className="text-xs text-gray-500 mt-0.5">{s.label}</div>
              </div>
            ))}
          </div>

          {/* Findings */}
          {summary.findings.length > 0 && (
            <section>
              <h3 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
                Findings
              </h3>
              <div className="space-y-3">
                {summary.findings.map((f, i) => (
                  <div key={i} className={`rounded-lg border p-4 ${f.rag_score <= 1 ? 'border-red-200 bg-red-50' : f.rag_score <= 2 ? 'border-orange-200 bg-orange-50' : f.rag_score === 3 ? 'border-amber-200 bg-amber-50' : 'border-gray-200 bg-white'}`}>
                    <div className="flex items-start justify-between gap-3 mb-2">
                      <span className="text-xs font-mono text-gray-500">{f.id || `F${i + 1}`}</span>
                      <SeverityBadge ragScore={f.rag_score} />
                    </div>
                    <p className="text-sm text-gray-800 leading-relaxed">{f.finding}</p>
                    {f.check_category && (
                      <p className="text-xs text-gray-500 mt-1">
                        Category: <span className="font-medium">{f.check_category}</span>
                      </p>
                    )}
                    {f.artifact_ref && (
                      <p className="text-xs text-gray-500 mt-0.5">
                        Artefact: <span className="font-medium">{f.artifact_ref}</span>
                      </p>
                    )}
                    {f.kb_ref && (
                      <p className="text-xs text-gray-500 mt-0.5">
                        KB Ref: <span className="font-medium">{f.kb_ref}</span>
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* Actions */}
          {summary.actions.length > 0 && (
            <section>
              <h3 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
                Required Actions
              </h3>
              <div className="space-y-2">
                {summary.actions.map((a, i) => (
                  <div key={i} className="border border-gray-200 rounded-lg p-3 bg-white">
                    <div className="flex items-start justify-between gap-2 mb-1">
                      <span className="text-xs font-mono text-gray-400">{a.id || `ACT-${i + 1}`}</span>
                      <div className="flex gap-1">
                        {a.priority && (
                          <span className={`text-xs px-2 py-0.5 rounded font-medium ${a.priority === 'HIGH' ? 'bg-red-100 text-red-700' : a.priority === 'MEDIUM' ? 'bg-amber-100 text-amber-700' : 'bg-gray-100 text-gray-600'}`}>
                            {a.priority}
                          </span>
                        )}
                      </div>
                    </div>
                    <p className="text-sm text-gray-800">{a.action}</p>
                    {(a.owner_role || a.due_days) && (
                      <p className="text-xs text-gray-500 mt-1">
                        {a.owner_role && <span>Owner: <span className="font-medium">{a.owner_role}</span></span>}
                        {a.due_days && <span className="ml-2">Due: <span className="font-medium">{a.due_days}d</span></span>}
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* ADRs */}
          {summary.adrs.length > 0 && (
            <section>
              <h3 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
                Architecture Decision Records
              </h3>
              <div className="space-y-2">
                {summary.adrs.map((adr, i) => (
                  <div key={i} className="border border-blue-100 rounded-lg p-3 bg-blue-50">
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-xs font-mono font-semibold text-blue-700">{adr.id || `ADR-${i + 1}`}</span>
                      {adr.type && (
                        <span className="text-xs px-2 py-0.5 rounded bg-blue-100 text-blue-700 font-medium">{adr.type}</span>
                      )}
                    </div>
                    <p className="text-sm font-medium text-gray-800">{adr.decision}</p>
                    {adr.rationale && (
                      <p className="text-xs text-gray-600 mt-1">{adr.rationale}</p>
                    )}
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* Recommendations */}
          {summary.recommendations.length > 0 && (
            <section>
              <h3 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
                Recommendations
              </h3>
              <div className="space-y-2">
                {summary.recommendations.map((r, i) => (
                  <div key={i} className="border border-gray-200 rounded-lg p-3 bg-white">
                    <div className="flex items-start justify-between gap-2 mb-1">
                      <span className="text-xs font-mono text-gray-400">{r.id || `REC-${i + 1}`}</span>
                      {r.priority && (
                        <span className={`text-xs px-2 py-0.5 rounded font-medium ${r.priority === 'HIGH' ? 'bg-red-100 text-red-700' : 'bg-gray-100 text-gray-600'}`}>
                          {r.priority}
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-gray-800">{r.recommendation}</p>
                  </div>
                ))}
              </div>
            </section>
          )}

          {summary.findings.length === 0 && summary.actions.length === 0 && summary.adrs.length === 0 && (
            <div className="text-center py-12 text-gray-400">
              <CheckCircle className="w-10 h-10 mx-auto mb-2 text-green-400" />
              <p className="text-sm">No issues found in this domain</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

// ── Domain Card ───────────────────────────────────────────────────────────────

function DomainCard({
  slug,
  summary,
  onClick,
}: {
  slug: string
  summary: DomainSummary
  onClick: () => void
}) {
  const meta  = DOMAIN_META[slug] || { label: slug, Icon: FileText }
  const style = ragStyle(summary.score)
  const Icon  = meta.Icon

  return (
    <button
      onClick={onClick}
      className={`w-full text-left rounded-xl border-2 p-5 transition-all hover:shadow-md hover:-translate-y-0.5 ${style.border} ${style.bg} group`}
    >
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className={`p-2 rounded-lg ${style.pill}`}>
            <Icon className="w-4 h-4" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900 text-sm leading-tight">{meta.label}</h3>
            <div className="flex items-center gap-1.5 mt-0.5">
              <span className={`w-2 h-2 rounded-full ${style.dot}`} />
              <span className={`text-xs font-bold ${style.text}`}>{summary.rag_label}</span>
            </div>
          </div>
        </div>
        <div className="flex flex-col items-center">
          <span className={`text-2xl font-black ${style.text}`}>{summary.score}</span>
          <span className="text-xs text-gray-400">/5</span>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-2 mb-4">
        <div className="text-center">
          <div className="text-lg font-bold text-gray-800">{summary.total_findings}</div>
          <div className="text-xs text-gray-500">Findings</div>
        </div>
        <div className="text-center">
          <div className={`text-lg font-bold ${summary.blocker_count > 0 ? 'text-red-600' : 'text-gray-800'}`}>
            {summary.blocker_count}
          </div>
          <div className="text-xs text-gray-500">Blockers</div>
        </div>
        <div className="text-center">
          <div className="text-lg font-bold text-gray-800">{summary.action_count}</div>
          <div className="text-xs text-gray-500">Actions</div>
        </div>
      </div>

      <div className={`flex items-center justify-between text-xs font-medium ${style.text} group-hover:gap-2 transition-all`}>
        <span>View domain details</span>
        <ChevronRight className="w-4 h-4 transition-transform group-hover:translate-x-0.5" />
      </div>
    </button>
  )
}

// ── Main Page ─────────────────────────────────────────────────────────────────

export default function ReviewDashboard() {
  const navigate    = useNavigate()
  const { submissionId } = useParams<{ submissionId: string }>()

  const [review,      setReview]      = useState<any>(null)
  const [loading,     setLoading]     = useState(true)
  const [error,       setError]       = useState<string | null>(null)
  const [activeSlug,  setActiveSlug]  = useState<string | null>(null)
  const [eaDecision,  setEaDecision]  = useState('')
  const [rationale,   setRationale]   = useState('')
  const [submitting,  setSubmitting]  = useState(false)

  useEffect(() => {
    if (!submissionId) return
    reviewService.getReviewById(submissionId)
      .then(data => { setReview(data); setLoading(false) })
      .catch(err  => { setError(err.message || 'Failed to load review'); setLoading(false) })
  }, [submissionId])

  // ── Derived data ────────────────────────────────────────────────────────────

  // Client-side fallback: build domain_summaries from report_json.ai_review if backend doesn't provide it
  const domainSummaries: Record<string, DomainSummary> = (() => {
    if (review?.domain_summaries && Object.keys(review.domain_summaries).length > 0) {
      return review.domain_summaries
    }

    // Fallback: build from report_json.ai_review
    const ai_review = review?.report_json?.ai_review || {}
    const findings_raw = [...(ai_review.findings || []), ...(ai_review.blockers || [])]
    const actions_raw = ai_review.actions || []
    const adrs_raw = ai_review.adrs || []
    const recs_raw = ai_review.recommendations || []
    const domain_scores_raw = ai_review.domain_scores || {}

    // Group by domain_slug
    const groupBySlug = (items: any[]) => {
      const grouped: Record<string, any[]> = {}
      for (const item of items) {
        const slug = item.domain_slug || item.domain || ""
        if (slug) {
          grouped[slug] = grouped[slug] || []
          grouped[slug].push(item)
        }
      }
      return grouped
    }

    const findingsByDomain = groupBySlug(findings_raw)
    const actionsByDomain = groupBySlug(actions_raw)
    const adrsByDomain = groupBySlug(adrs_raw)
    const recsByDomain = groupBySlug(recs_raw)

    // Get all domain slugs
    const allSlugs = new Set([
      ...Object.keys(domain_scores_raw),
      ...Object.keys(findingsByDomain),
      ...Object.keys(actionsByDomain),
      ...Object.keys(adrsByDomain),
      ...Object.keys(recsByDomain),
    ])

    const summaries: Record<string, DomainSummary> = {}
    for (const slug of allSlugs) {
      const f_list = findingsByDomain[slug] || []
      const a_list = actionsByDomain[slug] || []
      const r_list = adrsByDomain[slug] || []
      const rec_list = recsByDomain[slug] || []
      const score = domain_scores_raw[slug] || 3

      // Sort findings: blockers first (rag_score=1), then ascending score
      const f_sorted = [...f_list].sort((a, b) => (a.rag_score || 3) - (b.rag_score || 3))

      summaries[slug] = {
        score: score,
        rag_label: score <= 2 ? 'RED' : score === 3 ? 'AMBER' : 'GREEN',
        total_findings: f_list.length,
        blocker_count: f_list.filter(f => (f.rag_score || 5) <= 1).length,
        critical_count: f_list.filter(f => (f.rag_score || 5) <= 2).length,
        action_count: a_list.length,
        adr_count: r_list.length,
        findings: f_sorted,
        actions: a_list,
        adrs: r_list,
        recommendations: rec_list,
      }
    }

    return summaries
  })()

  const orderedSlugs = DOMAIN_ORDER.filter(s => domainSummaries[s])
    .concat(Object.keys(domainSummaries).filter(s => !DOMAIN_ORDER.includes(s)))

  // Client-side fallback for recommended_decision and aggregate_rag_score
  const recDecision = review?.recommended_decision || review?.report_json?.ai_review?.decision
  const aggScore    = review?.aggregate_rag_score ?? review?.report_json?.ai_review?.aggregate_score ?? 0
  const recMeta     = decisionMeta(recDecision)
  const RecIcon     = recMeta.Icon

  const totalFindings = orderedSlugs.reduce((n, s) => n + (domainSummaries[s]?.total_findings || 0), 0)
  const totalBlockers = orderedSlugs.reduce((n, s) => n + (domainSummaries[s]?.blocker_count  || 0), 0)
  const totalActions  = (review?.actions || []).length
  const totalADRs     = (review?.adrs    || []).length

  const aggStyle = ragStyle(aggScore)

  // ── EA actions ─────────────────────────────────────────────────────────────

  const handleAccept = async () => {
    if (!submissionId) return
    setSubmitting(true)
    try {
      await reviewService.updateDraft(submissionId, {
        status: 'approved',
      } as any)
      navigate('/dashboard')
    } catch (e: any) {
      alert(`Failed: ${e.message}`)
    } finally {
      setSubmitting(false)
    }
  }

  const handleOverride = async () => {
    if (!eaDecision || !rationale) {
      alert('Select a decision and provide rationale')
      return
    }
    setSubmitting(true)
    try {
      const resp = await fetch(
        `${(import.meta as any).env?.VITE_API_BASE_URL || '/api/v1'}/reviews/${submissionId}/override?decision=${eaDecision}&rationale=${encodeURIComponent(rationale)}`,
        { method: 'POST', headers: { Authorization: `Bearer ${localStorage.getItem('auth_token')}` } }
      )
      if (!resp.ok) throw new Error(await resp.text())
      navigate('/dashboard')
    } catch (e: any) {
      alert(`Failed: ${e.message}`)
    } finally {
      setSubmitting(false)
    }
  }

  const handleSendBack = async () => {
    if (!submissionId) return
    if (!confirm('Send this review back to the Solution Architect for rework?')) return
    setSubmitting(true)
    try {
      await reviewService.updateDraft(submissionId, { status: 'rework' } as any)
      navigate('/dashboard')
    } catch (e: any) {
      alert(`Failed: ${e.message}`)
    } finally {
      setSubmitting(false)
    }
  }

  // ── Render ──────────────────────────────────────────────────────────────────

  if (loading) return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center">
        <div className="w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full animate-spin mx-auto mb-3" />
        <p className="text-gray-500 text-sm">Loading ARB dossier…</p>
      </div>
    </div>
  )

  if (error) return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center">
        <AlertTriangle className="w-10 h-10 text-red-400 mx-auto mb-3" />
        <p className="text-red-600 font-medium">{error}</p>
        <Button variant="ghost" className="mt-4" onClick={() => navigate('/dashboard')}>Back to Dashboard</Button>
      </div>
    </div>
  )

  return (
    <div className="min-h-screen bg-gray-50">
      {/* ── Header ── */}
      <header className="bg-white border-b sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="sm" onClick={() => navigate('/dashboard')}>
              <ChevronLeft className="w-4 h-4 mr-1" /> Dashboard
            </Button>
            <div className="h-5 w-px bg-gray-200" />
            <div>
              <h1 className="text-base font-semibold text-gray-900 leading-tight">
                {review?.solution_name || 'ARB Review'}
              </h1>
              <p className="text-xs text-gray-400">{submissionId}</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <span className={`text-xs px-2.5 py-1 rounded-full font-semibold ${
              review?.status === 'ea_review'   ? 'bg-purple-100 text-purple-700' :
              review?.status === 'approved'    ? 'bg-green-100 text-green-700'   :
              review?.status === 'rejected'    ? 'bg-red-100 text-red-700'       :
              'bg-gray-100 text-gray-600'
            }`}>
              {(review?.status || '').replace(/_/g, ' ').toUpperCase()}
            </span>
            {review?.reviewed_at && (
              <span className="text-xs text-gray-400">
                Reviewed {new Date(review.reviewed_at).toLocaleDateString()}
              </span>
            )}
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-6 space-y-6">

        {/* ── AI Recommendation Banner ── */}
        {recDecision ? (
          <div className={`rounded-xl border-2 p-5 ${aggStyle.border} ${aggStyle.bg}`}>
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div className="flex items-center gap-4">
                <div className={`p-3 rounded-xl ${aggStyle.pill}`}>
                  <Zap className="w-6 h-6" />
                </div>
                <div>
                  <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">AI Agent Recommendation</p>
                  <div className="flex items-center gap-2 mt-1">
                    <RecIcon className="w-5 h-5" />
                    <span className={`text-xl font-black ${aggStyle.text}`}>
                      {recMeta.label.toUpperCase()}
                    </span>
                  </div>
                </div>
              </div>
              <div className="flex gap-6 text-center">
                <div>
                  <div className={`text-3xl font-black ${aggStyle.text}`}>{aggScore}</div>
                  <div className="text-xs text-gray-500">Agg. Score /5</div>
                </div>
                <div>
                  <div className={`text-3xl font-black ${totalBlockers > 0 ? 'text-red-700' : 'text-gray-700'}`}>{totalBlockers}</div>
                  <div className="text-xs text-gray-500">Blockers</div>
                </div>
                <div>
                  <div className="text-3xl font-black text-gray-700">{totalFindings}</div>
                  <div className="text-xs text-gray-500">Findings</div>
                </div>
                <div>
                  <div className="text-3xl font-black text-gray-700">{totalActions}</div>
                  <div className="text-xs text-gray-500">Actions</div>
                </div>
                <div>
                  <div className="text-3xl font-black text-gray-700">{totalADRs}</div>
                  <div className="text-xs text-gray-500">ADRs</div>
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="rounded-xl border border-dashed border-gray-300 bg-white p-6 text-center">
            <Clock className="w-8 h-8 text-gray-300 mx-auto mb-2" />
            <p className="text-gray-500 text-sm font-medium">AI review not yet complete</p>
            <p className="text-gray-400 text-xs mt-1">Trigger the review from the dashboard to run the AI agent.</p>
          </div>
        )}

        {/* ── Domain Cards Grid ── */}
        {orderedSlugs.length > 0 ? (
          <section>
            <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
              Domain Assessment — click a card to see findings
            </h2>
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {orderedSlugs.map(slug => (
                <DomainCard
                  key={slug}
                  slug={slug}
                  summary={domainSummaries[slug]}
                  onClick={() => setActiveSlug(slug)}
                />
              ))}
            </div>
          </section>
        ) : (
          recDecision && (
            <div className="bg-white rounded-xl border border-gray-200 p-8 text-center text-gray-400">
              <p className="text-sm">No domain-level data found. Re-run the AI review to populate domain summaries.</p>
            </div>
          )
        )}

        {/* ── ADRs Section ── */}
        {(review?.adrs || []).length > 0 && (
          <section>
            <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
              Architecture Decision Records ({review.adrs.length})
            </h2>
            <div className="grid gap-3 md:grid-cols-2">
              {review.adrs.map((adr: any) => (
                <div key={adr.id} className="bg-white rounded-xl border border-gray-200 p-4">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-mono font-semibold text-blue-700 bg-blue-50 px-2 py-0.5 rounded">
                      {adr.adr_id}
                    </span>
                    <span className={`text-xs px-2 py-0.5 rounded font-medium ${
                      adr.status === 'accepted'    ? 'bg-green-100 text-green-700' :
                      adr.status === 'rejected'    ? 'bg-red-100 text-red-700'    :
                      adr.status === 'conditional' ? 'bg-amber-100 text-amber-700' :
                      'bg-gray-100 text-gray-600'
                    }`}>
                      {adr.status}
                    </span>
                  </div>
                  <p className="text-sm font-semibold text-gray-800 mb-1">{adr.title || adr.decision}</p>
                  {adr.rationale && (
                    <p className="text-xs text-gray-500 line-clamp-2">{adr.rationale}</p>
                  )}
                  {adr.target_date && (
                    <p className="text-xs text-gray-400 mt-2">Target: {adr.target_date}</p>
                  )}
                </div>
              ))}
            </div>
          </section>
        )}

        {/* ── Actions Section ── */}
        {(review?.actions || []).length > 0 && (
          <section>
            <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
              Open Actions ({review.actions.filter((a: any) => a.status === 'open').length} open / {review.actions.length} total)
            </h2>
            <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b bg-gray-50">
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500">Action</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500">Owner</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500">Due</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {review.actions.map((ac: any) => (
                    <tr key={ac.id} className="border-b last:border-0 hover:bg-gray-50">
                      <td className="px-4 py-3 text-gray-800 max-w-sm">
                        <p className="line-clamp-2">{ac.action_text}</p>
                      </td>
                      <td className="px-4 py-3 text-gray-500 whitespace-nowrap">
                        {ac.owner_role?.replace(/_/g, ' ')}
                      </td>
                      <td className="px-4 py-3 text-gray-500 whitespace-nowrap">
                        {ac.due_date || (ac.due_days ? `${ac.due_days}d` : '—')}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`text-xs px-2 py-0.5 rounded font-medium ${
                          ac.status === 'completed'  ? 'bg-green-100 text-green-700' :
                          ac.status === 'in_progress' ? 'bg-blue-100 text-blue-700' :
                          'bg-amber-100 text-amber-700'
                        }`}>
                          {ac.status?.replace(/_/g, ' ')}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        )}

        {/* ── EA Decision Panel ── */}
        <section className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="text-base font-bold text-gray-900 mb-5">Enterprise Architect Decision</h2>

          {/* Accept recommendation */}
          {recDecision && (
            <div className="mb-6">
              <p className="text-sm text-gray-600 mb-3">
                Accept the AI agent recommendation:
                <span className={`ml-2 inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-semibold ${recMeta.color}`}>
                  <RecIcon className="w-3 h-3" /> {recMeta.label}
                </span>
              </p>
              <Button onClick={handleAccept} disabled={submitting} className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4" />
                Accept Recommendation
              </Button>
            </div>
          )}

          <div className="border-t pt-5 mb-5">
            <p className="text-sm font-medium text-gray-700 mb-3">Override decision</p>
            <div className="flex flex-wrap gap-2 mb-4">
              {(['approve', 'approve_with_conditions', 'defer', 'reject'] as const).map(d => (
                <button
                  key={d}
                  onClick={() => setEaDecision(d)}
                  className={`px-4 py-2 rounded-lg text-sm font-medium border transition-colors ${
                    eaDecision === d
                      ? 'bg-gray-900 text-white border-gray-900'
                      : 'bg-white text-gray-700 border-gray-300 hover:border-gray-500'
                  }`}
                >
                  {DECISION_META[d].label}
                </button>
              ))}
            </div>
            <Textarea
              value={rationale}
              onChange={e => setRationale(e.target.value)}
              placeholder="Provide rationale for your decision override…"
              rows={3}
              className="mb-3"
            />
            <Button
              onClick={handleOverride}
              disabled={submitting || !eaDecision || !rationale}
              variant="outline"
              className="flex items-center gap-2"
            >
              <AlertCircle className="w-4 h-4" />
              Submit Override
            </Button>
          </div>

          <div className="border-t pt-5">
            <p className="text-sm font-medium text-gray-700 mb-3">Send back for rework</p>
            <Button variant="outline" onClick={handleSendBack} disabled={submitting} className="flex items-center gap-2">
              <XCircle className="w-4 h-4" />
              Send Back to Solution Architect
            </Button>
          </div>
        </section>
      </main>

      {/* ── Domain Detail Panel ── */}
      {activeSlug && domainSummaries[activeSlug] && (
        <DomainDetailPanel
          slug={activeSlug}
          summary={domainSummaries[activeSlug]}
          onClose={() => setActiveSlug(null)}
        />
      )}
    </div>
  )
}
