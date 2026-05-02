"""
Enhanced ARB Orchestrator — aligned with the Pre-ARB AI Agent spec.

Key design choices (matching the Supabase edge-function behaviour):
- Sequential domain calls  (not parallel) — protects Gemini 15 RPM free-tier limit
- No LLM synthesis step    — each domain agent produces its own DomainReviewPayload;
                             the orchestrator aggregates them deterministically
- report_json merging      — ai_review key added alongside existing form_data
- rag_score based scoring  — domain score = summary.rag_score (1-5, LLM-authoritative)
- Decision logic           — matches TypeScript determineDecision()
"""

from __future__ import annotations

import asyncio
import logging
import time
from datetime import datetime, timezone
from typing import Any, Dict, List

from sqlalchemy.orm import Session

from app.agents.enhanced_domain_agents import EnhancedDomainValidationAgent, _rag_score_to_severity
from app.services.artefact_service import ArtefactService
from app.db.review_models import Review
from app.db.metadata_models import ChecklistQuestion

logger = logging.getLogger(__name__)

# Delay between sequential domain LLM calls — stays within 15 RPM free-tier limit.
INTER_DOMAIN_DELAY_S = 0.5

# One retry on transient LLM errors (503, timeout, etc.), 10 s delay.
# Retry (attempt 2) reduces KB + artefact content by 25% to stay under token limits.
LLM_CONTENT_SCALE_ON_SECOND_RETRY = 0.75


class EnhancedARBOrchestrator:
    """Orchestrates per-domain validation and aggregates results."""

    def __init__(self, db: Session):
        self.db              = db
        self.domain_agent    = EnhancedDomainValidationAgent(db)
        self.artefact_service = ArtefactService(db)

    # ── Public API ────────────────────────────────────────────────────────────

    async def run_review(
        self,
        review_id: str,
        checklist_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Run complete ARB review and return the merged report dict."""
        t0 = time.time()
        logger.info(f"[ORCHESTRATOR] Starting review={review_id}")

        review = self.db.query(Review).filter(Review.id == review_id).first()
        if not review:
            raise ValueError(f"Review {review_id} not found")

        domains = self._get_domains_from_scope(review.scope_tags or [])
        logger.info(f"[ORCHESTRATOR] Domains to process: {domains}")

        # ── Sequential domain calls ───────────────────────────────────────────
        domain_payloads: List[Dict[str, Any]] = []
        for domain_slug in domains:
            domain_checklist = dict(checklist_data.get("domain_data", {}).get(domain_slug, {}))
            domain_checklist["domain_metadata"] = {
                **self._get_domain_metadata(domain_slug),
                "solution_name": review.solution_name,
            }
            # For solution domain, pass full project info so the LLM can assess it
            if domain_slug == "solution":
                fd = (review.report_json or {}).get("form_data", {})
                domain_checklist["domain_metadata"].update({
                    "problem_statement":        fd.get("problem_statement", ""),
                    "business_drivers":         fd.get("business_drivers", []),
                    "stakeholders":             fd.get("stakeholders", []),
                    "target_business_outcomes": fd.get("growth_plans") or fd.get("target_business_outcomes", ""),
                })
            try:
                payload = await self._call_domain_with_retry(
                    review_id=review_id,
                    domain_slug=domain_slug,
                    domain_checklist=domain_checklist,
                )
                domain_payloads.append({"domain_slug": domain_slug, "payload": payload})
            except Exception as exc:
                logger.error(f"[ORCHESTRATOR] Domain {domain_slug} failed after all retries: {exc}")
                domain_payloads.append({
                    "domain_slug": domain_slug,
                    "payload": {
                        "domain": domain_slug,
                        "session_id": review_id,
                        "summary": {"rag_score": 3, "rag_label": "AMBER",
                                    "rationale": f"Validation error: {exc}",
                                    "total_findings": 0, "blocker_count": 0, "mandatory_gaps": 0},
                        "blockers": [], "recommendations": [],
                        "findings": [], "actions": [], "adrs": [],
                        "error": str(exc),
                    },
                })

            if domain_slug != domains[-1]:
                await asyncio.sleep(INTER_DOMAIN_DELAY_S)

        # ── Aggregate ─────────────────────────────────────────────────────────
        domain_scores: Dict[str, int] = {}
        all_findings:  List[Dict[str, Any]] = []
        all_blockers:  List[Dict[str, Any]] = []
        all_recommendations: List[Dict[str, Any]] = []
        all_actions:   List[Dict[str, Any]] = []
        all_adrs:      List[Dict[str, Any]] = []
        total_tokens = 0

        for entry in domain_payloads:
            slug    = entry["domain_slug"]
            payload = entry["payload"]
            summary = payload.get("summary", {})

            raw_score = summary.get("rag_score", 3)
            rag_score = max(1, min(5, int(raw_score)))
            domain_scores[slug] = rag_score

            # Findings enriched with domain slug
            for f in payload.get("findings", []):
                all_findings.append({**f, "domain_slug": slug})

            # Blockers (merged into findings with severity=critical in agent endpoint)
            for b in payload.get("blockers", []):
                all_blockers.append({**b, "domain_slug": slug})

            all_recommendations.extend(payload.get("recommendations", []))
            all_actions.extend(payload.get("actions", []))
            all_adrs.extend(payload.get("adrs", []))
            total_tokens += payload.get("tokens_used", 0)

        scores = list(domain_scores.values())

        # Spec-correct aggregate: min of all domain scores,
        # overridden to RED(1) if any Security/DR blocker exists.
        has_security_dr_blocker = any(
            b.get("is_security_or_dr") for b in all_blockers
        )
        if has_security_dr_blocker:
            aggregate_score = 1
        else:
            aggregate_score = min(scores) if scores else 3

        aggregate_rag_label = self._score_to_label(aggregate_score)
        decision            = self._determine_decision(aggregate_score, all_findings, all_blockers, domain_scores)

        # Collect kb_sources from all domain payloads
        kb_sources: List[str] = []
        for entry in domain_payloads:
            src = entry["payload"].get("summary", {}).get("kb_references") or []
            kb_sources.extend(src)
        kb_sources = list(dict.fromkeys(kb_sources))  # deduplicate, preserve order

        # Extract nfr_scorecard rows emitted by the NFR domain agent
        all_nfr_scorecard: List[Dict[str, Any]] = []
        for entry in domain_payloads:
            rows = entry["payload"].get("nfr_scorecard") or []
            all_nfr_scorecard.extend(rows)

        # Extract per-domain summaries (full DomainSummary objects)
        domain_summaries: Dict[str, Any] = {}
        for entry in domain_payloads:
            slug    = entry["domain_slug"]
            payload = entry["payload"]
            summary = dict(payload.get("summary", {}))
            summary["domain"] = slug
            domain_summaries[slug] = summary

        total_duration_s = time.time() - t0
        logger.info(
            f"[ORCHESTRATOR] Done — decision={decision} agg={aggregate_score}({aggregate_rag_label}) "
            f"findings={len(all_findings)} blockers={len(all_blockers)} "
            f"actions={len(all_actions)} adrs={len(all_adrs)} tokens={total_tokens} "
            f"duration={total_duration_s:.2f}s"
        )

        # ── Process NFR Criteria (form-based, for backward compat) ────────────
        nfr_analysis = self._process_nfr_criteria(review, domain_scores)

        # ── Build fullReport (merges into existing report_json) ───────────────
        existing_report_json = review.report_json or {}
        ai_review = {
            "decision":             decision,
            "aggregate_score":      aggregate_score,
            "aggregate_rag_label":  aggregate_rag_label,
            "domain_scores":        domain_scores,
            "domain_summaries":     domain_summaries,
            "findings":             all_findings,
            "blockers":             all_blockers,
            "recommendations":      all_recommendations,
            "actions":              all_actions,
            "adrs":                 all_adrs,
            "nfr_scorecard":        all_nfr_scorecard,
            "nfr_analysis":         nfr_analysis,
            "kb_sources_cited":     kb_sources,
            "processed_at":         datetime.now(timezone.utc).isoformat(),
        }

        return {
            **existing_report_json,
            "ai_review":              ai_review,
            "decision":               decision,
            "aggregate_score":        aggregate_score,
            "aggregate_rag_label":    aggregate_rag_label,
            "recommended_decision":   decision,
            "domain_scores":          domain_scores,
            "domain_summaries":       domain_summaries,
            "findings":               all_findings,
            "blockers":               all_blockers,
            "recommendations":        all_recommendations,
            "actions":                all_actions,
            "adrs":                   all_adrs,
            "nfr_scorecard":          all_nfr_scorecard,
            "kb_sources_cited":       kb_sources,
            "total_tokens_used":      total_tokens,
            "processing_time_seconds": total_duration_s,
            "domains_evaluated":      domains,
            "domain_payloads":        [e["payload"] for e in domain_payloads],
        }

    # ── Checklist preparation ─────────────────────────────────────────────────

    async def prepare_checklist_data(self, review_id: str) -> Dict[str, Any]:
        """Extract checklist items from report_json.form_data.domain_data."""
        review = self.db.query(Review).filter(Review.id == review_id).first()
        if not review or not review.report_json:
            logger.warning(f"[ORCHESTRATOR] No report_json for review {review_id}")
            return {"domain_data": {}}

        form_data = review.report_json.get("form_data", {})
        all_questions = self.db.query(ChecklistQuestion).all()
        question_cache = {q.question_code: q.question_text for q in all_questions}

        domain_data: Dict[str, Any] = {}

        # New schema: form_data.domain_data.{domain}.checklist
        for domain, data in form_data.get("domain_data", {}).items():
            items = []
            checklist = data.get("checklist", {})
            evidence  = data.get("evidence", {})
            for code, answer in checklist.items():
                items.append({
                    "question_code": code,
                    "question_text": question_cache.get(code, code),
                    "answer":        answer,
                    "evidence":      evidence.get(code, ""),
                })
            if items:
                domain_data[domain] = {"checklist_items": items}

        # Legacy schema: form_data.{domain}_checklist (backward compat)
        for key, value in form_data.items():
            if key.endswith("_checklist"):
                domain = key.replace("_checklist", "")
                if domain not in domain_data:  # Don't overwrite new schema if present
                    items = []
                    evidence_key = f"{domain}_evidence"
                    evidence = form_data.get(evidence_key, {})
                    for code, answer in value.items():
                        items.append({
                            "question_code": code,
                            "question_text": question_cache.get(code, code),
                            "answer":        answer,
                            "evidence":      evidence.get(code, ""),
                        })
                    if items:
                        domain_data[domain] = {"checklist_items": items}

        logger.info(f"[ORCHESTRATOR] Checklist prepared for {len(domain_data)} domains")
        return {"domain_data": domain_data}

    def _process_nfr_criteria(self, review: Review, domain_scores: Dict[str, int]) -> Dict[str, Any]:
        """Process NFR criteria from form data and analyze compliance"""
        if not review.report_json:
            return {"criteria": [], "summary": {"total_criteria": 0, "compliant_count": 0, "average_score": 0}}
        
        form_data = review.report_json.get("form_data", {})
        nfr_criteria = form_data.get("nfr_criteria", [])
        
        if not nfr_criteria:
            return {"criteria": [], "summary": {"total_criteria": 0, "compliant_count": 0, "average_score": 0}}
        
        processed_criteria = []
        compliant_count = 0
        total_score = 0
        
        for criterion in nfr_criteria:
            # Calculate compliance based on score
            score = criterion.get("score", 0)
            is_compliant = score >= 7  # 7+ out of 10 considered compliant
            if is_compliant:
                compliant_count += 1
            total_score += score
            
            # Determine compliance level
            if score >= 9:
                compliance_level = "fully_compliant"
            elif score >= 7:
                compliance_level = "compliant"
            elif score >= 5:
                compliance_level = "partially_compliant"
            else:
                compliance_level = "non_compliant"
            
            processed_criteria.append({
                "id": criterion.get("id"),
                "category": criterion.get("category"),
                "criteria": criterion.get("criteria"),
                "target_value": criterion.get("target_value"),
                "actual_value": criterion.get("actual_value"),
                "score": score,
                "compliance_level": compliance_level,
                "is_compliant": is_compliant,
                "evidence": criterion.get("evidence"),
            })
        
        # Calculate summary statistics
        total_criteria = len(processed_criteria)
        average_score = round(total_score / total_criteria, 1) if total_criteria > 0 else 0
        compliance_percentage = round((compliant_count / total_criteria) * 100, 1) if total_criteria > 0 else 0
        
        # Group by category for analysis
        category_analysis = {}
        for criterion in processed_criteria:
            category = criterion["category"]
            if category not in category_analysis:
                category_analysis[category] = {
                    "total": 0,
                    "compliant": 0,
                    "average_score": 0,
                    "scores": []
                }
            
            category_analysis[category]["total"] += 1
            category_analysis[category]["scores"].append(criterion["score"])
            if criterion["is_compliant"]:
                category_analysis[category]["compliant"] += 1
        
        # Calculate category averages
        for category, analysis in category_analysis.items():
            if analysis["scores"]:
                analysis["average_score"] = round(sum(analysis["scores"]) / len(analysis["scores"]), 1)
                analysis["compliance_percentage"] = round((analysis["compliant"] / analysis["total"]) * 100, 1)
            del analysis["scores"]  # Remove raw scores to clean up output
        
        # Generate NFR domain score (affects overall decision)
        nfr_domain_score = min(5, max(1, round(average_score / 2)))  # Convert 0-10 to 1-5 scale
        
        return {
            "criteria": processed_criteria,
            "summary": {
                "total_criteria": total_criteria,
                "compliant_count": compliant_count,
                "non_compliant_count": total_criteria - compliant_count,
                "average_score": average_score,
                "compliance_percentage": compliance_percentage,
                "nfr_domain_score": nfr_domain_score
            },
            "category_analysis": category_analysis
        }

    # ── Retry wrapper ─────────────────────────────────────────────────────────

    async def _call_domain_with_retry(
        self,
        review_id: str,
        domain_slug: str,
        domain_checklist: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Call validate_domain with 1 retry, 10 s apart.

        Attempt 1 — full content.
        Attempt 2 (retry, 10 s) — KB + artefact content reduced by 25 %
                                 to stay within LLM token limits.
        """
        delays = [0, 10]  # 2 total attempts
        last_exc: Exception = RuntimeError("no attempts made")
        for attempt, delay in enumerate(delays, start=1):
            if delay > 0:
                logger.warning(
                    f"[ORCHESTRATOR] {domain_slug} attempt {attempt} — "
                    f"retrying in {delay}s after: {last_exc}"
                )
                await asyncio.sleep(delay)
            # Reduce content on the second attempt (retry)
            content_scale = LLM_CONTENT_SCALE_ON_SECOND_RETRY if attempt == 2 else 1.0
            if content_scale < 1.0:
                logger.info(
                    f"[ORCHESTRATOR] {domain_slug} attempt {attempt} — "
                    f"reducing KB/artefact content to {int(content_scale * 100)}%"
                )
            try:
                return await self.domain_agent.validate_domain(
                    review_id=review_id,
                    domain_slug=domain_slug,
                    checklist_data=domain_checklist,
                    content_scale=content_scale,
                )
            except Exception as exc:
                last_exc = exc
                logger.warning(f"[ORCHESTRATOR] {domain_slug} attempt {attempt} failed: {exc}")
        raise last_exc

    # ── Internal helpers ──────────────────────────────────────────────────────

    def _get_domains_from_scope(self, scope_tags: List[str]) -> List[str]:
        """Return ordered list of domain slugs to evaluate."""
        from app.db.metadata_models import Domain
        active = {d.slug for d in self.db.query(Domain).filter(Domain.is_active == True).all()}

        ordered = []
        for tag in scope_tags:
            if tag in active and tag not in ordered:
                ordered.append(tag)
        # Always include solution domain first if available
        if "solution" in active and "solution" not in ordered:
            ordered.insert(0, "solution")
        return ordered

    def _score_to_label(self, score: int) -> str:
        if score >= 4:
            return "green"
        if score == 3:
            return "amber"
        return "red"

    def _get_domain_metadata(self, domain_slug: str) -> Dict[str, Any]:
        from app.db.metadata_models import Domain
        domain = self.db.query(Domain).filter(Domain.slug == domain_slug, Domain.is_active == True).first()
        if not domain:
            return {"name": domain_slug.title(), "description": ""}
        return {
            "name":        domain.name,
            "description": domain.description or "",
            "seq_number":  domain.seq_number,
        }

    def _determine_decision(
        self,
        aggregate_score: int,
        findings: List[Dict[str, Any]],
        blockers: List[Dict[str, Any]],
        domain_scores: Dict[str, int],
    ) -> str:
        """Spec-correct decision logic matching the orchestrator aggregation rules."""
        has_security_dr_blocker = any(b.get("is_security_or_dr") for b in blockers)
        blocker_count = len(blockers)

        # Score 5 or 4 → APPROVE (minor tracked actions only)
        if aggregate_score >= 4 and blocker_count == 0:
            return "approve"
        # Score 1 with Security/DR blocker → REJECT
        if aggregate_score <= 1 and has_security_dr_blocker:
            return "reject"
        # Score 1 other blocker → DEFER
        if aggregate_score <= 1 or blocker_count > 0:
            return "defer"
        # Score 2 or 3 → APPROVE_WITH_CONDITIONS
        return "approve_with_conditions"
