"""
Enhanced Domain Validation Agent — aligned with the Pre-ARB AI Agent spec.

Prompt structure mirrors the TypeScript edge-function orchestrator:
  SYSTEM  → role + 10 RULES + SCORING RULES
  USER    → REVIEW SESSION / KB CONTEXT / SA ARTIFACTS / CHECKLIST /
            ID SEED / MANDATORY CATEGORIES / OUTPUT SCHEMA

Output: DomainReviewPayload  (summary, blockers, recommendations, findings, actions, adrs)
"""

from __future__ import annotations

import logging
import time
import uuid as uuid_mod
from typing import Any, Dict, List, Optional

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.services.llm_service import llm_service, LLMService
from app.services.artefact_service import ArtefactService
from app.db.review_models import AuditLog, Review

logger = logging.getLogger(__name__)

# ── Domain metadata ────────────────────────────────────────────────────────────

DOMAIN_CODE: Dict[str, str] = {
    "general":        "GEN",
    "business":       "BUS",
    "application":    "APP",
    "integration":    "INT",
    "data":           "DAT",
    "security":       "SEC",
    "infrastructure": "INF",
    "devsecops":      "DSO",
    "nfr":            "NFR",
}

DOMAIN_LABEL: Dict[str, str] = {
    "general":        "General Architecture",
    "business":       "Business Domain",
    "application":    "Application Domain",
    "integration":    "Integration Domain",
    "data":           "Data Domain",
    "security":       "Security Domain",
    "infrastructure": "Infrastructure & Platform",
    "devsecops":      "DevSecOps Domain",
    "nfr":            "Non-Functional Requirements",
}

# Maps Python domain slug → question_registry.frontend_tab values
# (frontend_tab uses full slug names matching the Python DB)
DOMAIN_TO_QR_TABS: Dict[str, List[str]] = {
    "general":        ["general"],
    "business":       ["business"],
    "application":    ["application"],
    "integration":    ["integration"],
    "data":           ["data"],
    "security":       ["infrastructure", "nfr"],  # infra-sec-* + nfr-sec-*
    "infrastructure": ["infrastructure"],
    "devsecops":      ["devsecops"],
    "nfr":            ["nfr"],
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _rag_score_to_severity(rag_score: int) -> str:
    """Map LLM rag_score (1-5) to DB findings.severity constraint values."""
    if rag_score <= 1:
        return "critical"
    if rag_score <= 2:
        return "major"
    return "minor"


# ── Domain Agent ──────────────────────────────────────────────────────────────

class EnhancedDomainValidationAgent:
    """Per-domain LLM agent producing a spec-compliant DomainReviewPayload."""

    def __init__(self, db: Session):
        self.db = db
        self.llm_service: LLMService = llm_service
        self.artefact_service = ArtefactService(db)

    # ── Main entry point ──────────────────────────────────────────────────────

    async def validate_domain(
        self,
        review_id: str,
        domain_slug: str,
        checklist_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Validate a single domain and return a DomainReviewPayload dict."""
        t0 = time.time()
        logger.info(f"[DOMAIN-AGENT] validate_domain domain={domain_slug} review={review_id}")

        domain_code  = DOMAIN_CODE.get(domain_slug, domain_slug.upper()[:3])
        domain_label = DOMAIN_LABEL.get(domain_slug, domain_slug.title())

        # 1. Artefact chunks
        chunks = await self.artefact_service.get_relevant_chunks(
            review_id=review_id, domain_slug=domain_slug, limit=15
        )
        logger.info(f"[DOMAIN-AGENT] {domain_slug}: {len(chunks)} artefact chunks")

        # 2. Knowledge-base context (domain + general)
        kb_domain  = await self.artefact_service.search_knowledge_base(
            query=f"{domain_slug} architecture principles standards",
            category=domain_slug, limit=8,
        )
        kb_general = await self.artefact_service.search_knowledge_base(
            query="enterprise architecture principles", category="general", limit=4,
        )
        kb_results = kb_domain + kb_general
        logger.info(f"[DOMAIN-AGENT] {domain_slug}: {len(kb_results)} KB articles")

        # 3. Check categories from question_registry
        check_categories = self._get_check_categories(domain_slug)

        # 4. NFR quantitative criteria (only for nfr domain)
        nfr_context = ""
        if domain_slug == "nfr":
            review = self.db.query(Review).filter(Review.id == review_id).first()
            nfr_context = self._build_nfr_criteria_block(review)

        # 5. Build prompts (spec structure)
        system_prompt = self._build_system_prompt(domain_label)
        user_prompt   = self._build_user_prompt(
            session_id=review_id,
            domain_slug=domain_slug,
            domain_code=domain_code,
            checklist_data=checklist_data,
            chunks=chunks,
            kb_results=kb_results,
            check_categories=check_categories,
            nfr_context=nfr_context,
        )

        # 6. Call LLM — audit both success and failure paths
        logger.info(f"[DOMAIN-AGENT] calling LLM for {domain_slug}")
        try:
            response = await self.llm_service.generate_completion(
                prompt=user_prompt,
                system_prompt=system_prompt,
                temperature=0.3,
                max_tokens=8192,
            )
        except Exception as llm_exc:
            self._audit_llm(
                review_id, domain_slug,
                response=None, error=llm_exc,
                user_prompt=user_prompt, system_prompt=system_prompt,
            )
            raise

        self._audit_llm(
            review_id, domain_slug,
            response=response, error=None,
            user_prompt=user_prompt, system_prompt=system_prompt,
        )

        # 7. Parse DomainReviewPayload
        try:
            payload = LLMService.parse_json_from_llm(response["content"])
        except Exception as exc:
            logger.error(f"[DOMAIN-AGENT] JSON parse failed for {domain_slug}: {exc}")
            logger.debug(f"[DOMAIN-AGENT] raw={response['content'][:400]}")
            payload = {
                "domain": domain_slug,
                "session_id": review_id,
                "summary": {"rag_score": 3, "rag_label": "AMBER",
                            "rationale": "Parse error — manual review required",
                            "total_findings": 0, "blocker_count": 0, "mandatory_gaps": 0},
                "blockers": [], "recommendations": [],
                "findings": [], "actions": [], "adrs": [],
            }

        payload["tokens_used"]          = response.get("tokens_used", 0)
        payload["artefact_chunks_used"] = len(chunks)
        payload["kb_articles_used"]     = len(kb_results)

        logger.info(
            f"[DOMAIN-AGENT] {domain_slug} done in {time.time()-t0:.2f}s "
            f"rag_score={payload.get('summary', {}).get('rag_score')} "
            f"findings={len(payload.get('findings', []))} "
            f"blockers={len(payload.get('blockers', []))}"
        )
        return payload

    # ── Audit helper ──────────────────────────────────────────────────────────

    def _audit_llm(
        self,
        review_id: str,
        domain_slug: str,
        response: Optional[Dict],
        error: Optional[Exception],
        user_prompt: str = "",
        system_prompt: str = "",
    ) -> None:
        """Write one audit_log row recording the LLM call outcome for this domain.

        Uses a fresh DB session so the write is unaffected by the state of the
        shared session (e.g. an aborted transaction from a prior domain failure).
        """
        from app.core.database import SessionLocal
        try:
            meta: Dict[str, Any] = {
                "domain_slug":   domain_slug,
                "request": {
                    "system_prompt": system_prompt,
                    "user_prompt":   user_prompt,
                },
            }
            if response is not None:
                meta.update({
                    "status":       "success",
                    "model":        response.get("model"),
                    "provider":     response.get("provider"),
                    "tokens_used":  response.get("tokens_used", 0),
                    "raw_response": response.get("content", ""),
                })
            if error is not None:
                meta.update({
                    "status":     "error",
                    "error":      str(error),
                    "error_type": type(error).__name__,
                })
            log_entry = AuditLog(
                review_id=uuid_mod.UUID(review_id),
                action="llm_domain_review",
                audit_metadata=meta,
            )
            audit_db = SessionLocal()
            try:
                audit_db.add(log_entry)
                audit_db.commit()
            finally:
                audit_db.close()
        except Exception as log_exc:
            logger.warning(f"[DOMAIN-AGENT] audit log failed ({log_exc})")

    # ── System prompt (spec §RULES + SCORING RULES) ───────────────────────────

    def _build_system_prompt(self, domain_label: str) -> str:
        return f"""You are the {domain_label} specialist agent in the Pre-ARB AI Agent pipeline.
Your role is to validate the Solution Architect's submitted artifacts against
enterprise architecture standards and produce a structured JSON review payload.

RULES:
1. Respond ONLY with a valid JSON object matching DomainReviewPayload schema.
   No preamble, no markdown, no explanation outside the JSON.
2. Every finding must reference a specific SA artifact AND a specific KB document.
   Never generate findings from general knowledge alone.
3. Every Blocker must have rag_score = 1 and appear in both findings[] and blockers[].
4. Every finding with rag_score <= 3 (AMBER or RED) must have at least one Action in actions[].
5. Every significant architectural decision or deviation must have an ADR in adrs[].
6. ADRs of type WAIVER must include a proposed waiver_expiry_date (ISO date string).
7. summary.rag_score must equal min(all finding rag_scores). You cannot score AMBER if any finding is RED.
8. If evidence is absent for a mandatory check, set rag_score = 1 (RED). Never skip mandatory categories.
9. Do not invent evidence. If it is not present in the provided artifacts, flag its absence explicitly.
10. Security domain rule: any finding with rag_score < 4 must generate a Blocker record.

SCORING RULES:
5 = Fully compliant — all evidence present, no gaps
4 = Compliant with minor tracked actions only
3 = Partially compliant — gaps exist but mitigation plan is documented
2 = Significant gaps — mandatory remediation actions required before go-live
1 = Fails mandatory standard OR evidence is absent (RED / BLOCKER)"""

    # ── User prompt (all spec sections) ──────────────────────────────────────

    def _build_user_prompt(
        self,
        session_id:       str,
        domain_slug:      str,
        domain_code:      str,
        checklist_data:   Dict[str, Any],
        chunks:           List[Dict[str, Any]],
        kb_results:       List[Dict[str, Any]],
        check_categories: List[Dict[str, Any]],
        nfr_context:      str,
    ) -> str:
        from datetime import datetime, timezone

        review_date    = datetime.now(timezone.utc).isoformat()
        domain_label   = DOMAIN_LABEL.get(domain_slug, domain_slug.title())
        solution_name  = checklist_data.get("domain_metadata", {}).get("solution_name", "(not provided)")

        # --- KB section ---
        kb_lines: List[str] = []
        for i, kb in enumerate(kb_results[:10], 1):
            kb_lines.append(f"\n[KB-{i:02d} | {kb.get('principle_id', 'N/A')}]\n{kb['title']}\n{kb['content']}")
        kb_block = "\n".join(kb_lines) if kb_lines else "(No KB entries loaded for this domain.)"

        # --- SA Artifacts section ---
        artifact_lines: List[str] = []
        for i, chunk in enumerate(chunks[:15], 1):
            artifact_lines.append(
                f"\n--- Artefact {i}: {chunk.get('filename', 'Unknown')} ---\n{chunk['chunk_text']}"
            )
        artifact_block = "\n".join(artifact_lines) if artifact_lines else "(No artefact content available.)"
        if nfr_context:
            artifact_block += f"\n\n{nfr_context}"

        # --- Checklist section ---
        checklist_lines: List[str] = []
        items = checklist_data.get("checklist_items", [])
        for item in items:
            q    = item.get("question_text", item.get("question", "N/A"))
            code = item.get("question_code", "")
            ans  = item.get("answer", "not_answered")
            ev   = item.get("evidence", "") or "(none provided)"
            checklist_lines.append(
                f"  {code:<15}  {q}\n"
                f"             Answer:   {ans.upper()}\n"
                f"             Evidence: {ev}"
            )
        checklist_block = "\n".join(checklist_lines) if checklist_lines else "(No checklist items provided.)"

        # --- Mandatory check categories ---
        if check_categories:
            cat_lines = []
            for c in check_categories:
                flag = "  [MANDATORY-GREEN] " if c["is_mandatory_green"] else "  "
                suffix = "  ← non_compliant or not_answered = BLOCKER" if c["is_mandatory_green"] else ""
                cat_lines.append(f"{flag}{c['category']}{suffix}")
            categories_block = "\n".join(cat_lines)
        else:
            categories_block = "  (no categories registered — use check_category from checklist above)"

        return f"""== REVIEW SESSION ==
session_id: {session_id}
solution_name: {solution_name}
domain_under_review: {domain_code}
review_date: {review_date}

== SOLUTION CONTEXT ==
Domain: {domain_label}
Domain Description: {checklist_data.get("domain_metadata", {}).get("description", "")}

== KNOWLEDGE BASE CONTEXT (retrieved for this domain) ==
{kb_block}

== SA SUBMITTED ARTIFACTS ==
{artifact_block}

== SA CHECKLIST ANSWERS & EVIDENCE ==
{checklist_block}

== ID SEED ==
finding_id_start:        {domain_code}-F01
blocker_id_start:        {domain_code}-BLK-01
recommendation_id_start: {domain_code}-REC-01
action_id_start:         {domain_code}-ACT-01
adr_id_start:            ADR-{domain_code}-01
Use these as starting IDs, incrementing sequentially (F01, F02, F03 ...).

== MANDATORY CHECK CATEGORIES FOR THIS DOMAIN ==
Produce at least one Finding for each category below.
Categories marked [MANDATORY-GREEN] require rag_score = 1 if the SA answer is non_compliant or not_answered.

{categories_block}

== OUTPUT SCHEMA ==
Return a JSON object with this exact top-level structure. No markdown. No prose outside the JSON.

{{
  "domain": "{domain_code}",
  "session_id": "{session_id}",
  "summary": {{
    "rag_score": 3,
    "rag_label": "GREEN | AMBER | RED",
    "rationale": "One-sentence justification for the domain rag_score",
    "total_findings": 0,
    "blocker_count": 0,
    "mandatory_gaps": 0
  }},
  "blockers": [
    {{
      "id": "{domain_code}-BLK-01",
      "finding_ref": "{domain_code}-F01",
      "description": "Precise description of the blocking issue",
      "resolution_required": "Specific action that must be completed before approval"
    }}
  ],
  "recommendations": [
    {{
      "id": "{domain_code}-REC-01",
      "finding_ref": "{domain_code}-F01",
      "recommendation": "Specific improvement recommendation",
      "priority": "HIGH | MEDIUM | LOW"
    }}
  ],
  "findings": [
    {{
      "id": "{domain_code}-F01",
      "check_category": "CATEGORY_FROM_LIST_ABOVE",
      "rag_score": 1,
      "rag_label": "GREEN | AMBER | RED",
      "finding": "Clear description referencing the specific SA artifact gap and relevant KB document",
      "artifact_ref": "File name or section in SA submission where evidence was sought",
      "kb_ref": "KB document ID or title that defines the standard",
      "principle_id": "EA principle code if applicable, else null"
    }}
  ],
  "actions": [
    {{
      "id": "{domain_code}-ACT-01",
      "finding_ref": "{domain_code}-F01",
      "action": "Specific, measurable remediation step",
      "owner_role": "solution_architect | enterprise_architect | dev_team | security_team",
      "due_days": 30,
      "priority": "HIGH | MEDIUM | LOW"
    }}
  ],
  "adrs": [
    {{
      "id": "ADR-{domain_code}-01",
      "type": "DECISION | WAIVER",
      "decision": "Decision title",
      "rationale": "Why this decision is being made",
      "context": "Background context (optional)",
      "owner": "Role or team responsible",
      "target_date": "YYYY-MM-DD or null",
      "waiver_expiry_date": "YYYY-MM-DD — required when type = WAIVER, else null"
    }}
  ]
}}"""

    # ── Check categories from question_registry ───────────────────────────────

    def _get_check_categories(self, domain_slug: str) -> List[Dict[str, Any]]:
        """Return unique check_category rows for the domain from question_registry.
        Falls back to checklist_subsections if question_registry is not populated.
        """
        tabs = DOMAIN_TO_QR_TABS.get(domain_slug, [domain_slug])
        placeholders = ", ".join(f":tab{i}" for i in range(len(tabs)))
        params = {f"tab{i}": t for i, t in enumerate(tabs)}

        try:
            with self.db.begin_nested():
                rows = self.db.execute(text(f"""
                    SELECT check_category,
                           bool_or(is_mandatory_green) AS is_mandatory_green
                    FROM   question_registry
                    WHERE  frontend_tab IN ({placeholders})
                    AND    is_active = true
                    GROUP  BY check_category
                    ORDER  BY check_category
                """), params).fetchall()

            if rows:
                return [{"category": r[0], "is_mandatory_green": bool(r[1])} for r in rows]
        except Exception as exc:
            logger.warning(f"[DOMAIN-AGENT] question_registry query failed ({exc}), using subsections fallback")

        # Fallback: checklist_subsections (existing Python metadata tables)
        try:
            from app.db.metadata_models import Domain, ChecklistSubsection, ChecklistQuestion
            domain_obj = self.db.query(Domain).filter(Domain.slug == domain_slug).first()
            if not domain_obj:
                return []
            subsections = (
                self.db.query(ChecklistSubsection)
                .filter(ChecklistSubsection.domain_id == domain_obj.id, ChecklistSubsection.is_active == True)
                .order_by(ChecklistSubsection.sort_order)
                .all()
            )
            result = []
            for sub in subsections:
                has_required = (
                    self.db.query(ChecklistQuestion)
                    .filter(ChecklistQuestion.subsection_id == sub.id, ChecklistQuestion.is_required == True)
                    .count() > 0
                )
                result.append({"category": sub.name, "is_mandatory_green": has_required})
            return result
        except Exception as exc2:
            logger.warning(f"[DOMAIN-AGENT] subsections fallback also failed ({exc2})")
            return []

    # ── NFR criteria block (nfr domain only) ─────────────────────────────────

    def _build_nfr_criteria_block(self, review: Optional[Review]) -> str:
        if not review or not review.report_json:
            return ""
        rows = (review.report_json.get("form_data") or {}).get("nfr_criteria", [])
        if not rows:
            return "== NFR QUANTITATIVE CRITERIA — none provided by SA =="
        lines = [
            f"== NFR QUANTITATIVE CRITERIA ({len(rows)} rows) ==",
            "Use these to calibrate SCALABILITY_PERFORMANCE and HA_RESILIENCE scores.",
            "",
            "Category           | Criteria              | Target      | Actual       | Score | Evidence",
            "-------------------|----------------------|-------------|--------------|-------|----------",
        ]
        for r in rows:
            lines.append(" | ".join([
                str(r.get("category",     "")).ljust(18),
                str(r.get("criteria",     "")).ljust(21),
                str(r.get("target_value", "")).ljust(11),
                str(r.get("actual_value", "")).ljust(12),
                str(r.get("score",        "?")).ljust(5),
                str(r.get("evidence",     "(none)")),
            ]))
        return "\n".join(lines)
