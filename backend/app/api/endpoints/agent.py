"""
Agent orchestration endpoint.

POST /api/v1/agent/review  {reviewId} → trigger ARB review, persist results.
GET  /api/v1/agent/test-llm           → LLM connectivity check.

Persistence rules (aligned with Supabase edge-function behaviour):
- review.status   → "ea_review"  (not "pending")
- review.decision → lowercase DB value  (approve | approve_with_conditions | defer | reject)
- review.report_json → merged: existing form_data kept, ai_review key added
- findings.severity → "critical" | "major" | "minor"  (DB constraint values)
- actions.status  → "open"     (DB constraint)
- adrs.status     → "proposed" (DB constraint)
- DomainScore     → upsert on (review_id, domain) to survive re-runs
- Findings        → delete-then-insert on re-run to avoid duplicates
"""

from __future__ import annotations

import logging
from datetime import date, datetime, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_access_token
from app.agents.enhanced_orchestrator import EnhancedARBOrchestrator
from app.agents.enhanced_domain_agents import _rag_score_to_severity

logger = logging.getLogger(__name__)
router = APIRouter()


# ── Auth helper ───────────────────────────────────────────────────────────────

async def get_current_user(authorization: Optional[str] = Header(None)) -> Optional[str]:
    if not authorization or not authorization.startswith("Bearer "):
        return None
    payload = decode_access_token(authorization.split(" ", 1)[1])
    return payload.get("sub") if payload else None


# ── Normalisation helpers ─────────────────────────────────────────────────────

def _normalise_decision(raw: str) -> str:
    """Map any casing of LLM decision to the DB constraint values."""
    mapping = {
        "approve":                "approve",
        "approve_with_conditions": "approve_with_conditions",
        "approvewithconditions":  "approve_with_conditions",
        "defer":                  "defer",
        "reject":                 "reject",
    }
    return mapping.get(raw.lower().replace(" ", "_"), "defer")


def _parse_date(value: Any) -> Optional[date]:
    """Best-effort parse of a date string from LLM output."""
    if not value or not isinstance(value, str):
        return None
    try:
        return datetime.strptime(value[:10], "%Y-%m-%d").date()
    except ValueError:
        return None


def _due_date_from_days(due_days: Any) -> Optional[date]:
    if not due_days:
        return None
    try:
        days = int(due_days)
        return (datetime.now(timezone.utc) + __import__("datetime").timedelta(days=days)).date()
    except (TypeError, ValueError):
        return None


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/review")
async def trigger_review(
    request: Dict[str, str],
    current_user: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Trigger ARB review orchestrator and persist results."""
    if not current_user:
        raise HTTPException(status_code=401, detail="Authentication required")

    review_id = request.get("reviewId")
    if not review_id:
        raise HTTPException(status_code=400, detail="reviewId is required")

    logger.info(f"[AGENT] trigger_review review_id={review_id} user={current_user}")

    try:
        orchestrator = EnhancedARBOrchestrator(db)
        result = await orchestrator.run_review(
            review_id=review_id,
            checklist_data=await orchestrator.prepare_checklist_data(review_id),
        )
    except Exception as exc:
        logger.exception(f"[AGENT] Orchestration failed for {review_id}")
        raise HTTPException(status_code=500, detail=f"Review orchestration failed: {exc}")

    # ── Persist results ───────────────────────────────────────────────────────
    try:
        _persist_results(db, review_id, result)
    except Exception as exc:
        logger.error(f"[AGENT] Persistence error for {review_id}: {exc}", exc_info=True)
        # Don't fail the HTTP response — log and return result anyway

    return {
        "success":    True,
        "reviewId":   review_id,
        "decision":   result.get("decision"),
        "report":     result,
        "tokensUsed": result.get("total_tokens_used", 0),
    }


@router.get("/test-llm")
async def test_llm(current_user: str = Depends(get_current_user)):
    from app.services.llm_service import llm_service
    try:
        result = await llm_service.generate_completion(
            prompt='{"test": "Say exactly: Hello from ARB AI Agent"}',
            system_prompt='You are a test assistant. Respond only with valid JSON.',
            temperature=0.1,
            max_tokens=64,
            timeout=30,
        )
        return {"success": True, "provider": result.get("provider"),
                "model": result.get("model"), "response": result.get("content"),
                "tokens_used": result.get("tokens_used")}
    except Exception as exc:
        from app.services.llm_service import llm_service as svc
        return {"success": False, "error": str(exc), "provider": svc.provider}


# ── Persistence ───────────────────────────────────────────────────────────────

def _persist_results(db: Session, review_id: str, result: Dict[str, Any]) -> None:
    from app.db.review_models import Review, DomainScore, Finding, ADR, Action

    # 1. Update review row ────────────────────────────────────────────────────
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        logger.error(f"[AGENT] Review {review_id} not found — cannot persist")
        return

    review.decision           = _normalise_decision(result.get("decision", "defer"))
    review.status             = "ea_review"
    review.tokens_used        = result.get("total_tokens_used", 0)
    review.processing_time_ms = int(result.get("processing_time_seconds", 0) * 1000)
    review.reviewed_at        = datetime.now(timezone.utc)

    # Merge ai_review into existing report_json (preserve form_data)
    existing = review.report_json or {}
    review.report_json = {
        **existing,
        "ai_review": result.get("ai_review", {
            "decision":        result.get("decision"),
            "aggregate_score": result.get("aggregate_score"),
            "domain_scores":   result.get("domain_scores", {}),
            "findings":        result.get("findings", []),
            "blockers":        result.get("blockers", []),
            "recommendations": result.get("recommendations", []),
            "actions":         result.get("actions", []),
            "adrs":            result.get("adrs", []),
            "processed_at":    datetime.now(timezone.utc).isoformat(),
        }),
    }
    db.add(review)
    db.flush()
    logger.info(f"[AGENT] Review row updated decision={review.decision} status={review.status}")

    # 2. Domain scores (upsert on review_id + domain) ─────────────────────────
    for domain_slug, score in result.get("domain_scores", {}).items():
        existing_score = (
            db.query(DomainScore)
            .filter(DomainScore.review_id == review_id, DomainScore.domain == domain_slug)
            .first()
        )
        if existing_score:
            existing_score.score = int(score)
        else:
            db.add(DomainScore(review_id=review_id, domain=domain_slug, score=int(score)))
    db.flush()
    logger.info(f"[AGENT] Domain scores saved: {list(result.get('domain_scores', {}).keys())}")

    # 3. Findings (delete-then-insert to avoid duplicates on re-run) ──────────
    db.query(Finding).filter(Finding.review_id == review_id).delete()

    all_findings: List[Dict[str, Any]] = list(result.get("findings", []))

    # Also insert blockers as critical findings
    for blk in result.get("blockers", []):
        all_findings.append({
            "domain_slug":   blk.get("domain_slug", ""),
            "principle_id":  "",
            "rag_score":     1,
            "finding":       blk.get("description", ""),
            "recommendation": blk.get("resolution_required", ""),
            "check_category": "BLOCKER",
        })

    for f in all_findings:
        raw_score = f.get("rag_score", 3)
        severity  = _rag_score_to_severity(int(raw_score) if str(raw_score).isdigit() else 3)
        db.add(Finding(
            review_id     = review_id,
            domain        = f.get("domain_slug") or f.get("domain", ""),
            principle_id  = f.get("principle_id") or None,
            severity      = severity,          # critical | major | minor
            finding       = f.get("finding", ""),
            recommendation= f.get("recommendation") or None,
            is_resolved   = False,
        ))
    db.flush()
    logger.info(f"[AGENT] Findings saved: {len(all_findings)}")

    # 4. Actions ──────────────────────────────────────────────────────────────
    for act in result.get("actions", []):
        raw_days = act.get("due_days")
        try:
            due_days = int(raw_days) if raw_days is not None else None
        except (TypeError, ValueError):
            due_days = None

        due_date = _due_date_from_days(due_days)
        db.add(Action(
            review_id  = review_id,
            action_text= act.get("action", ""),
            owner_role = act.get("owner_role", "solution_architect"),
            due_days   = due_days,
            due_date   = due_date,
            status     = "open",   # DB constraint: open | in_progress | completed | blocked
        ))
    db.flush()
    logger.info(f"[AGENT] Actions saved: {len(result.get('actions', []))}")

    # 5. ADRs ─────────────────────────────────────────────────────────────────
    for i, adr in enumerate(result.get("adrs", []), start=1):
        adr_type         = adr.get("type", "DECISION")
        waiver_expiry    = adr.get("waiver_expiry_date")
        consequences_txt = f"waiver_expiry_date: {waiver_expiry}" if adr_type == "WAIVER" and waiver_expiry else None

        db.add(ADR(
            review_id   = review_id,
            adr_id      = adr.get("id") or f"ADR-{review_id[:8]}-{i:03d}",
            decision    = adr.get("decision", ""),
            rationale   = adr.get("rationale", ""),
            context     = adr.get("context") or None,
            consequences= consequences_txt,
            owner       = adr.get("owner") or None,
            target_date = _parse_date(adr.get("target_date")),
            status      = "proposed",  # DB constraint: proposed | accepted | rejected | superseded
        ))
    db.flush()
    logger.info(f"[AGENT] ADRs saved: {len(result.get('adrs', []))}")

    db.commit()
    logger.info(f"[AGENT] All results committed for review={review_id}")
