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
    "solution":       "SOL",
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
    "solution":       "Solution",
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
    "solution":       ["solution"],
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
        content_scale: float = 1.0,
    ) -> Dict[str, Any]:
        """Validate a single domain and return a DomainReviewPayload dict.

        content_scale (0 < scale ≤ 1.0): multiplier applied to chunk and KB
        fetch limits. Pass < 1.0 on retries to reduce token usage.
        """
        t0 = time.time()
        logger.info(
            f"[DOMAIN-AGENT] validate_domain domain={domain_slug} review={review_id} "
            f"content_scale={content_scale}"
        )

        domain_code  = DOMAIN_CODE.get(domain_slug, domain_slug.upper()[:3])
        domain_label = DOMAIN_LABEL.get(domain_slug, domain_slug.title())

        chunk_limit  = max(1, int(15 * content_scale))
        kb_dom_limit = max(1, int(8  * content_scale))
        kb_gen_limit = max(1, int(4  * content_scale))

        # 1. Artefact chunks
        chunks = await self.artefact_service.get_relevant_chunks(
            review_id=review_id, domain_slug=domain_slug, limit=chunk_limit
        )
        logger.info(f"[DOMAIN-AGENT] {domain_slug}: {len(chunks)} artefact chunks (limit={chunk_limit})")

        # 2. Knowledge-base context (domain + general)
        kb_domain  = await self.artefact_service.search_knowledge_base(
            query=f"{domain_slug} architecture principles standards",
            category=domain_slug, limit=kb_dom_limit,
        )
        kb_general = await self.artefact_service.search_knowledge_base(
            query="enterprise architecture principles", category="solution", limit=kb_gen_limit,
        )
        kb_results = kb_domain + kb_general
        logger.info(f"[DOMAIN-AGENT] {domain_slug}: {len(kb_results)} KB articles (limits={kb_dom_limit}+{kb_gen_limit})")

        # 3. Check categories from question_registry
        check_categories = self._get_check_categories(domain_slug)

        # 4. NFR quantitative criteria (only for nfr domain)
        nfr_context = ""
        if domain_slug == "nfr":
            review = self.db.query(Review).filter(Review.id == review_id).first()
            nfr_context = self._build_nfr_criteria_block(review)

        # 5. Build prompts (spec structure)
        system_prompt = self._build_system_prompt(domain_label, domain_slug)
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
                temperature=0.5,
                max_tokens=16384,
                timeout=120,
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
        raw_content = response.get("content") or ""
        logger.debug(f"[DOMAIN-AGENT] raw LLM response for {domain_slug}: {raw_content[:800]}")
        try:
            payload = LLMService.parse_json_from_llm(raw_content)
        except Exception as exc:
            logger.error(f"[DOMAIN-AGENT] JSON parse failed for {domain_slug}: {exc}")
            logger.error(f"[DOMAIN-AGENT] First 200 chars: {raw_content[:200]}")
            logger.error(f"[DOMAIN-AGENT] Last 200 chars: {raw_content[-200:] if len(raw_content) > 200 else raw_content}")
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
            f"blockers={len(payload.get('blockers', []))} "
            f"actions={len(payload.get('actions', []))} "
            f"adrs={len(payload.get('adrs', []))}"
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

    def _build_system_prompt(self, domain_label: str, domain_slug: str = "") -> str:
        return f"""You are a senior {domain_label} architect acting as a specialist reviewer in the Pre-ARB AI Agent pipeline.
Your role is to conduct a thorough, proportionate review of the Solution Architect's submission against
enterprise architecture standards — producing a balanced assessment that reflects real-world ARB practice.

RULES:
1. Respond ONLY with a valid JSON object matching DomainReviewPayload schema.
   No preamble, no markdown, no explanation outside the JSON.

2. Every finding MUST reference a specific SA artifact section OR a relevant KB document.
   Focus on material gaps affecting architecture quality, security, or operability.
   When the SA has addressed a requirement with reasonable evidence (even if not in the prescribed format),
   credit it and note the finding as GREEN or AMBER rather than inventing a gap.

3. RAG scoring — calibrate proportionately:
   • rag_score 1 (BLOCKER): Critical gaps preventing approval — unmitigated security risks,
     absent mandatory compliance evidence, critical domain with no design at all.
   • rag_score 2 (RED): Significant gaps requiring mandatory remediation before go-live.
   • rag_score 3 (AMBER): Gaps present but a clear remediation path exists; trackable post-approval.
   • rag_score 4 (GREEN+): Area well-addressed; only minor follow-up actions logged.
   • rag_score 5 (GREEN): Fully addressed — key evidence present, approach aligns with EA standards.
   Reserve rag_score 1–2 for genuinely critical issues. Prefer AMBER (3) for non-critical gaps.
   Use rag_score 4 liberally when the SA has done solid work with minor loose ends.

4. Every finding with rag_score <= 3 (AMBER or RED) MUST have at least one Action in actions[].

5. Generate ADRs for decisions and exceptions that warrant formal recording (aim for 1–3 per domain):
   MANDATORY — you MUST generate an ADR for each of these:
   - Any finding with rag_score 1 (BLOCKER) → type: WAIVER (formal exception required before approval)
   - Any finding with rag_score 2 (RED) → type: WAIVER (significant gap needing formal exception)
   - Technology or vendor choices that deviate from EA standards → type: DECISION
   - Architectural patterns that differ materially from the standard approach → type: DECISION
   OPTIONAL (generate only if clearly applicable):
   - Notable AMBER decisions that set a precedent or need tracking → type: DECISION
   Do NOT generate ADRs for routine GREEN findings or straightforward remediation items.
   adrs[] MUST NOT be empty if any finding has rag_score <= 2.

6. ADRs of type WAIVER must include a proposed waiver_expiry_date (ISO date string).

7. summary.rag_score reflects overall domain readiness — calibrate against the finding distribution:
   - Mostly GREEN (4–5) with 1–2 minor AMBERs → summary GREEN (4)
   - Mix of GREEN and AMBER, no blockers → summary AMBER (3)
   - Any rag_score=2 finding OR multiple AMBERs without mitigations → summary RED (2)
   - Any blocker (rag_score=1) → summary RED (1)
   The summary should represent what an ARB panel would conclude about this domain's readiness.

8. When evidence is absent, apply proportionate judgment:
   - Critical domain (security controls, DR/HA, compliance): absent evidence → rag_score 1–2
   - Non-critical / advisory: absent evidence → rag_score 3 with a documented action
   - Evidence quality matters: a vague "will be addressed post-launch" does NOT satisfy a mandatory check.
     Require a documented plan, owner, and timeline to credit rag_score 3; anything weaker is rag_score 2.
   - Evidence that addresses the INTENT of a requirement in alternate format: credit appropriately.

9. Do not invent evidence. Flag genuine absences explicitly — note WHAT is missing and WHY it matters.
   When the SA has documented their rationale for a deviation, assess whether the rationale is adequate
   rather than automatically flagging as non-compliant.

10. Security domain: any rag_score ≤ 2 finding requires a corresponding Blocker entry.

PRAGMATISM GUIDELINES:
- Calibrate against the solution's risk profile. A customer-facing, regulated system warrants stricter
  scrutiny than an internal analytics tool. Let the problem statement and stakeholder context inform weight.
- Distinguish mandatory enterprise standards from best-practice guidance. Flag violations of the former
  as RED/AMBER; treat the latter as recommendations with LOW priority.
- The knowledge base may not cover every scenario. Where KB guidance is sparse, apply professional
  judgment informed by the solution's context and general architecture principles.
- Accept evidence addressing the INTENT of a requirement, even if not in the exact prescribed format.
- For intentional design trade-offs (e.g., MVP simplicity over full resilience), assess whether the
  trade-off is proportionate, documented, and time-bounded — not just whether it follows the standard.
- When the SA has made a well-reasoned deviation with documented rationale, acknowledge it explicitly
  and assess the rationale's adequacy rather than treating silence and bad reasoning the same way.

COVERAGE REQUIREMENT:
- Assess every check category listed in the prompt. For fully addressed categories,
  a GREEN finding (rag_score 4–5) that briefly acknowledges compliance IS the correct output.
  Do not manufacture concerns for well-covered areas. Do not skip any category.

SCORING RULES:
5 = Fully compliant — key evidence present, approach clearly aligned with EA standards, no material gaps
4 = Compliant — area well-addressed; only minor tracked actions remain (e.g., doc update, monitoring config)
3 = Partially compliant — material gaps present but SA has a credible, time-bound remediation plan
2 = Significant gaps — mandatory remediation required; go-live should be conditional on resolution
1 = Fails mandatory standard OR critical evidence absent with no documented mitigation (BLOCKER)""" + ("""

SOLUTION DOMAIN — SPECIALIST GUIDANCE:
As the Solution reviewer your primary responsibility is to assess whether this submission is
problem-driven, well-defined, and strategically aligned — not just technically complete.

KEY ASSESSMENT AREAS (generate a finding for each, even if all artefacts are absent):
- PROBLEM_STATEMENT_QUALITY: Is the problem clearly articulated, customer-grounded, and measurable?
  A vague or generic problem statement → rag_score 2.  Absent problem statement → rag_score 1.
  A clear, specific, measurable problem linked to a customer or business pain → rag_score 4–5.
- SOLUTION_FIT: Does the proposed solution directly address the root cause of the stated problem?
  Assess alignment between the problem description and the architectural approach in the artefacts.
- BUSINESS_OUTCOMES: Are target outcomes Specific, Measurable, Achievable, Relevant, Time-bound?
  Generic outcomes ("improve performance", "reduce cost") without metrics → rag_score 2–3.
  SMART outcomes with measurable KPIs and timelines → rag_score 4–5.
- STAKEHOLDER_ALIGNMENT: Are key stakeholders identified with clear ownership and accountability?
- STRATEGIC_FIT: Does the solution align with the stated enterprise business drivers?

WEIGHTING — PROBLEM STATEMENT:
The problem statement quality carries significant weight in the overall domain score.
A solution with strong technical artefacts but a vague or absent problem statement should score
no higher than rag_score 3 (AMBER) for this domain overall.
A well-framed problem with SMART outcomes and demonstrated solution-fit warrants rag_score 4–5.

OUTPUT ADDITION — include a "project_context" object at the top level of your JSON response:
{
  "project_context": {
    "problem_statement_assessed": "Brief restatement of the SA's problem as you understood it",
    "problem_statement_quality": "clear | vague | absent",
    "outcomes_measurability": "measurable | partial | not_measurable | absent",
    "solution_fit_assessment": "One sentence on how well the solution addresses the stated problem"
  }
}""" if domain_slug == "solution" else "")

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
        meta           = checklist_data.get("domain_metadata", {})
        solution_name  = meta.get("solution_name", "(not provided)")

        # --- Project info block (always brief; expanded for solution domain) ---
        problem_statement       = meta.get("problem_statement", "(not provided)")
        business_drivers        = meta.get("business_drivers", [])
        stakeholders            = meta.get("stakeholders", [])
        target_business_outcomes = meta.get("target_business_outcomes", "(not provided)")

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
                suffix = "  ← non_compliant = BLOCKER" if c["is_mandatory_green"] else ""
                cat_lines.append(f"{flag}{c['category']}{suffix}")
            categories_block = "\n".join(cat_lines)
        else:
            categories_block = "  (no categories registered — use check_category from checklist above)"

        # --- Solution context block ---
        if domain_slug == "solution":
            solution_context_block = f"""== PROJECT INFORMATION (PRIMARY ASSESSMENT CONTEXT) ==
Solution Name:            {solution_name}
Problem Statement:        {problem_statement}
Business Drivers:         {'; '.join(business_drivers) if business_drivers else '(not provided)'}
Stakeholders:             {', '.join(stakeholders) if stakeholders else '(not provided)'}
Target Business Outcomes: {target_business_outcomes}

ASSESSMENT INSTRUCTIONS:
1. Assess the QUALITY of the problem statement — not just whether one was provided.
   A strong problem statement identifies the customer/stakeholder, describes the pain or opportunity,
   quantifies the impact, and is specific enough to evaluate solution-fit.
2. Assess whether target outcomes are SMART (Specific, Measurable, Achievable, Relevant, Time-bound).
3. Assess solution-fit: does the architectural approach in the artefacts directly address the problem?
   Document gaps or misalignments explicitly.
4. Generate a PROBLEM_STATEMENT_QUALITY finding and a BUSINESS_OUTCOMES finding regardless of other coverage."""
        else:
            solution_context_block = f"""== SOLUTION CONTEXT ==
Solution Name:    {solution_name}
Problem Summary:  {problem_statement}
Domain:           {domain_label}
Description:      {checklist_data.get("domain_metadata", {}).get("description", "")}"""

        project_context_schema_hint = (
            '\nInclude "project_context" as the first key (Solution domain only):\n'
            '  "project_context": {\n'
            '    "problem_statement_assessed": "Brief restatement of the SA\'s problem as you understood it",\n'
            '    "problem_statement_quality": "clear | vague | absent",\n'
            '    "outcomes_measurability": "measurable | partial | not_measurable | absent",\n'
            '    "solution_fit_assessment": "One sentence: how well the solution addresses the stated problem"\n'
            '  },\n'
            if domain_slug == "solution" else ""
        )

        return f"""== REVIEW SESSION ==
session_id: {session_id}
solution_name: {solution_name}
domain_under_review: {domain_code}
review_date: {review_date}

{solution_context_block}

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
Assess each category below and produce a finding that accurately reflects the actual state:
  - Fully compliant area → GREEN finding (rag_score 4–5) briefly acknowledging coverage is the correct output.
  - Partial compliance or minor gap → AMBER finding (rag_score 3) with a time-bound action.
  - Critical gap or non-compliant mandatory check → RED finding (rag_score 1–2) with a blocker or action.
Do not manufacture concerns for well-addressed areas. Do not skip any listed category.
Categories marked [MANDATORY-GREEN] require rag_score = 1 if the SA answer is non_compliant
(check artifact evidence first — adequate mitigating evidence can raise this to rag_score 2).

{categories_block}

== OUTPUT SCHEMA ==
Return a JSON object with this exact top-level structure. No markdown. No prose outside the JSON.
{project_context_schema_hint}
{{
  "domain": "{domain_code}",
  "session_id": "{session_id}",
  "summary": {{
    "rag_score": 3,
    "rag_label": "GREEN | AMBER | RED",
    "overall_readiness": "APPROVE | APPROVE_WITH_CONDITIONS | DEFER | REJECT",
    "rationale": "One-sentence justification for the domain rag_score",
    "executive_summary": "3-5 sentences covering: current state, key strengths, critical gaps, ARB readiness",
    "compliant_areas": ["Area 1 — references specific standard or pattern", "Area 2"],
    "gap_areas": ["{domain_code}-F01: Short gap description", "{domain_code}-F02: ..."],
    "total_findings": 0,
    "blocker_count": 0,
    "action_count": 0,
    "adr_count": 0,
    "mandatory_gaps": 0,
    "evidence_quality": "COMPLETE | PARTIAL | INSUFFICIENT | ABSENT",
    "domain_specific_scores": {{}},
    "kb_references": ["KB-DOC-ID-1", "KB-DOC-ID-2"]
  }},
  "blockers": [
    {{
      "id": "{domain_code}-BLK-01",
      "domain": "{domain_code}",
      "title": "Specific title ≤120 chars — name the control or standard violated",
      "description": "1-3 sentences: what is missing/failing, which SA artifact, why non-compliant",
      "violated_standard": "Standard name and version e.g. Security Standards v2.4 §3.2",
      "impact": "Specific business or technical consequence if unresolved",
      "resolution_required": "Exact artifact or evidence the SA must produce to close this",
      "links_to_finding_id": "{domain_code}-F01",
      "is_security_or_dr": false,
      "status": "OPEN",
      "kb_evidence_ref": ["KB-DOC-ID"]
    }}
  ],
  "recommendations": [
    {{
      "id": "{domain_code}-REC-01",
      "domain": "{domain_code}",
      "priority": "CRITICAL | HIGH | MEDIUM | LOW",
      "title": "Action-verb lead: Implement X for Y — specific to this solution",
      "rationale": "Why this recommendation applies to this specific solution (1-2 sentences)",
      "approved_pattern_ref": "Pattern or standard name and version from KB",
      "benefit": "Specific measurable or verifiable benefit",
      "implementation_hint": "Optional: concrete first step for the SA",
      "applies_to_finding_id": "{domain_code}-F01 or null",
      "is_agent_generated": true,
      "kb_source_ref": ["KB-DOC-ID"]
    }}
  ],
  "findings": [
    {{
      "id": "{domain_code}-F01",
      "check_category": "CATEGORY_FROM_LIST_ABOVE",
      "rag_score": 4,
      "rag_label": "GREEN | AMBER | RED",
      "title": "[what is wrong or confirmed] in [specific component/artifact] — ≤140 chars",
      "finding": "Balanced assessment: what the SA addressed well and any specific gap (reference artifact or KB)",
      "description": "2-4 sentences: what was found, in which SA artifact, why it is non-compliant or compliant",
      "evidence_source": "File name or section in SA submission where evidence was reviewed",
      "standard_violated": "Exact standard, policy or principle violated with version — null if GREEN",
      "impact": "Specific risk if unresolved — null if GREEN",
      "recommendation": "1-2 sentences: specific remediation action — null if no action required",
      "is_blocker": false,
      "waiver_eligible": false,
      "artifact_ref": "File name or section in SA submission",
      "kb_ref": "KB document ID or title that defines the standard",
      "principle_id": "EA principle code if applicable, else null",
      "kb_reference": ["KB-DOC-ID"]
    }}
  ],
  "actions": [
    {{
      "id": "{domain_code}-ACT-01",
      "domain": "{domain_code}",
      "action_type": "BLOCKER_RESOLUTION | AMBER_CONDITION | DOCUMENTATION | EVIDENCE_SUBMISSION | WAIVER_APPLICATION | POST_GO_LIVE",
      "title": "Action-verb lead — specific enough to act without reading the finding",
      "action": "Specific, measurable remediation step",
      "proposed_owner": "solution_architect | enterprise_architect | dev_team | security_team",
      "owner_role": "solution_architect | enterprise_architect | dev_team | security_team",
      "proposed_due_date": "BEFORE_ARB | WITHIN_2_WEEKS | WITHIN_30_DAYS | WITHIN_60_DAYS | WITHIN_QUARTER | PRE_GO_LIVE",
      "due_days": 30,
      "priority": "CRITICAL | HIGH | MEDIUM | LOW",
      "verification_method": "How completion will be verified — specific artifact or review step",
      "is_conditional_approval_gate": false,
      "links_to_finding_id": "{domain_code}-F01",
      "links_to_blocker_id": "{domain_code}-BLK-01 or null"
    }}
  ],
  "adrs": [
    {{
      "id": "ADR-{domain_code}-01",
      "domain": "{domain_code}",
      "adr_type": "NEW_DECISION | WAIVER | DEVIATION | RATIFICATION | DEPRECATION",
      "title": "Decision: [verb + specific choice] or Waiver: [specific deviation]",
      "decision": "The chosen option and its key parameters — specific, not vague",
      "rationale": "Why this option was chosen, referencing architecture principles or KB patterns",
      "context": "2-4 sentences: why this decision was needed",
      "consequences": "Both positive outcomes and trade-offs accepted",
      "mitigations": ["Specific mitigation for each risk in consequences"],
      "options_considered": [
        {{"option_label": "A", "description": "Option A description", "pros": ["pro1"], "cons": ["con1"]}},
        {{"option_label": "B", "description": "Option B description", "pros": ["pro1"], "cons": ["con1"]}}
      ],
      "proposed_owner": "Role responsible for implementing this ADR",
      "owner": "Role or team responsible",
      "proposed_target_date": "IMMEDIATE | WITHIN_30_DAYS | WITHIN_QUARTER | NEXT_RELEASE | ONGOING",
      "target_date": "YYYY-MM-DD or null",
      "waiver_expiry_date": "YYYY-MM-DD — REQUIRED when adr_type = WAIVER, else null",
      "links_to_finding_ids": ["{domain_code}-F01"],
      "status": "PROPOSED",
      "kb_references": ["KB-DOC-ID"]
    }}
  ],
  "nfr_scorecard": []
}}

NFR_SCORECARD NOTE: Populate nfr_scorecard[] only when domain = "NFR". Each row:
{{
  "nfr_category": "SCALABILITY_PERFORMANCE | HA_RESILIENCE | SECURITY | DEVSECOPS_QUALITY | ENGINEERING_EXCELLENCE | DR",
  "rag_score": 3,
  "rag_label": "GREEN | AMBER | RED",
  "evidence_provided": ["specific evidence item from SA"],
  "gaps": ["specific gap vs SLO baseline"],
  "mitigating_condition": "What must be done to close the gap — empty string if GREEN",
  "slo_target": "Platform SLO target e.g. P95 < 3s, Four-9s HA",
  "actual_evidenced": "What the SA actually evidenced vs the SLO target",
  "is_mandatory_green": false
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
