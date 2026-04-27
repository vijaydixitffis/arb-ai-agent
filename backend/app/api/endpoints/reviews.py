from fastapi import APIRouter, Depends, HTTPException, Header
from typing import List, Optional
import logging
from app.core.database import get_db
from app.core.security import decode_access_token
from app.services.review_service import ReviewService
from app.utils.schema_validation import validate_review_data_structure, validate_submission_completeness, get_validation_summary
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

router = APIRouter()

async def get_current_user(authorization: Optional[str] = Header(None)) -> tuple[Optional[str], Optional[str]]:
    """Extract user ID and role from JWT token"""
    if not authorization:
        return None, None
    if not authorization.startswith("Bearer "):
        return None, None
    token = authorization.split(" ")[1]
    payload = decode_access_token(token)
    if not payload:
        return None, None
    return payload.get("sub"), payload.get("role")

@router.get("/")
async def get_reviews(user_id: str = None, current_user: tuple = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get ARB reviews - all authenticated users can read"""
    user_id_token, user_role = current_user
    if not user_id_token:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    service = ReviewService(db)
    reviews = service.get_all_reviews()
    
    # SA, EA, ARB Admin can read all reviews
    # Filter by user if user_id is provided (for getUserReviews)
    if user_id:
        reviews = [r for r in reviews if str(r.sa_user_id) == user_id]
    
    # Convert to dict format for JSON response
    return [
        {
            "id": str(review.id),
            "created_at": review.created_at.isoformat() if review.created_at else None,
            "submitted_at": review.submitted_at.isoformat() if review.submitted_at else None,
            "reviewed_at": review.reviewed_at.isoformat() if review.reviewed_at else None,
            "sa_user_id": str(review.sa_user_id) if review.sa_user_id else None,
            "solution_name": review.solution_name,
            "scope_tags": review.scope_tags,
            "status": review.status,
            "decision": review.decision,
            "llm_model": review.llm_model,
            "tokens_used": review.tokens_used,
            "processing_time_ms": review.processing_time_ms,
            "llm_raw_response": review.llm_raw_response,
            "ea_user_id": str(review.ea_user_id) if review.ea_user_id else None,
            "ea_override_notes": review.ea_override_notes,
            "ea_overridden_at": review.ea_overridden_at.isoformat() if review.ea_overridden_at else None,
            "report_json": review.report_json
        }
        for review in reviews
    ]

@router.get("/{review_id}")
async def get_review(review_id: str, current_user: tuple = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get a specific ARB review - all authenticated users can read"""
    user_id_token, user_role = current_user
    if not user_id_token:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    service = ReviewService(db)
    review = service.get_review(review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    # Fetch related data
    from app.db.review_models import DomainScore, Finding, ADR, Action
    domain_scores = db.query(DomainScore).filter(DomainScore.review_id == review.id).all()
    findings = db.query(Finding).filter(Finding.review_id == review.id).all()
    adrs = db.query(ADR).filter(ADR.review_id == review.id).all()
    actions = db.query(Action).filter(Action.review_id == review.id).all()
    
    return {
        "id": str(review.id),
        "created_at": review.created_at.isoformat() if review.created_at else None,
        "submitted_at": review.submitted_at.isoformat() if review.submitted_at else None,
        "reviewed_at": review.reviewed_at.isoformat() if review.reviewed_at else None,
        "sa_user_id": str(review.sa_user_id) if review.sa_user_id else None,
        "solution_name": review.solution_name,
        "scope_tags": review.scope_tags,
        "status": review.status,
        "decision": review.decision,
        "llm_model": review.llm_model,
        "tokens_used": review.tokens_used,
        "processing_time_ms": review.processing_time_ms,
        "llm_raw_response": review.llm_raw_response,
        "ea_user_id": str(review.ea_user_id) if review.ea_user_id else None,
        "ea_override_notes": review.ea_override_notes,
        "ea_overridden_at": review.ea_overridden_at.isoformat() if review.ea_overridden_at else None,
        "report_json": review.report_json,
        "domain_scores": [
            {
                "id": str(ds.id),
                "review_id": str(ds.review_id),
                "domain": ds.domain,
                "score": ds.score,
                "created_at": ds.created_at.isoformat() if ds.created_at else None
            }
            for ds in domain_scores
        ],
        "findings": [
            {
                "id": str(f.id),
                "review_id": str(f.review_id),
                "domain": f.domain,
                "principle_id": f.principle_id,
                "severity": f.severity,
                "title": f.finding,
                "description": f.finding,
                "recommendation": f.recommendation,
                "is_resolved": f.is_resolved,
                "created_at": f.created_at.isoformat() if f.created_at else None
            }
            for f in findings
        ],
        "adrs": [
            {
                "id": str(a.id),
                "review_id": str(a.review_id),
                "adr_id": a.adr_id,
                "title": a.decision,
                "status": a.status,
                "content": a.rationale,
                "decision": a.decision,
                "rationale": a.rationale,
                "context": a.context,
                "consequences": a.consequences,
                "owner": a.owner,
                "target_date": a.target_date.isoformat() if a.target_date else None,
                "created_at": a.created_at.isoformat() if a.created_at else None
            }
            for a in adrs
        ],
        "actions": [
            {
                "id": str(ac.id),
                "review_id": str(ac.review_id),
                "action_text": ac.action_text,
                "status": ac.status,
                "owner_role": ac.owner_role,
                "due_days": ac.due_days,
                "due_date": ac.due_date.isoformat() if ac.due_date else None,
                "created_at": ac.created_at.isoformat() if ac.created_at else None
            }
            for ac in actions
        ]
    }

@router.post("/")
async def create_review(review_data: dict, current_user: tuple = Depends(get_current_user), db: Session = Depends(get_db)):
    """Create a new ARB review with enhanced validation"""
    user_id_token, _ = current_user
    if not user_id_token:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    # Enhanced validation - use draft mode for initial creation
    is_draft = review_data.get('status') == 'draft'
    
    # Check form_data in report_json (where frontend sends it) or at root level
    form_data = None
    if 'report_json' in review_data and isinstance(review_data['report_json'], dict):
        form_data = review_data['report_json'].get('form_data')
    elif 'form_data' in review_data:
        form_data = review_data['form_data']
    
    if form_data:
        form_validation = validate_submission_completeness(form_data, is_draft=is_draft)
        if not form_validation.is_valid:
            raise HTTPException(
                status_code=400, 
                detail={
                    "error": "Form data validation failed",
                    "validation_errors": form_validation.errors,
                    "validation_warnings": form_validation.warnings,
                    "summary": get_validation_summary(form_validation)
                }
            )
        
        # Log warnings for monitoring
        if form_validation.warnings:
            logger.warning(f"Review creation form validation warnings: {form_validation.warnings}")
    
    # Basic review structure validation
    validation = validate_review_data_structure(review_data)
    if not validation.is_valid:
        raise HTTPException(
            status_code=400, 
            detail={
                "error": "Review structure validation failed",
                "validation_errors": validation.errors,
                "validation_warnings": validation.warnings,
                "summary": get_validation_summary(validation)
            }
        )
    
    # Log warnings for monitoring
    if validation.warnings:
        logger.warning(f"Review creation warnings: {validation.warnings}")
    
    service = ReviewService(db)
    review = service.create_review(review_data)
    
    return {
        "id": str(review.id),
        "created_at": review.created_at.isoformat() if review.created_at else None,
        "submitted_at": review.submitted_at.isoformat() if review.submitted_at else None,
        "reviewed_at": review.reviewed_at.isoformat() if review.reviewed_at else None,
        "sa_user_id": str(review.sa_user_id) if review.sa_user_id else None,
        "solution_name": review.solution_name,
        "scope_tags": review.scope_tags,
        "status": review.status,
        "decision": review.decision,
        "llm_model": review.llm_model,
        "tokens_used": review.tokens_used,
        "processing_time_ms": review.processing_time_ms,
        "llm_raw_response": review.llm_raw_response,
        "ea_user_id": str(review.ea_user_id) if review.ea_user_id else None,
        "ea_override_notes": review.ea_override_notes,
        "ea_overridden_at": review.ea_overridden_at.isoformat() if review.ea_overridden_at else None,
        "report_json": review.report_json,
        "validation_warnings": validation.warnings  # Return warnings for frontend awareness
    }

@router.put("/{review_id}")
async def update_review(review_id: str, review_data: dict, current_user: tuple = Depends(get_current_user), db: Session = Depends(get_db)):
    """Update an existing ARB review with enhanced validation - EA, ARB Admin, and Solution Architect (for their own drafts)"""
    user_id_token, user_role = current_user
    if not user_id_token:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    # Enhanced validation for form_data updates
    # Check form_data in report_json (where frontend sends it) or at root level
    form_data = None
    if 'report_json' in review_data and isinstance(review_data['report_json'], dict):
        form_data = review_data['report_json'].get('form_data')
    elif 'form_data' in review_data:
        form_data = review_data['form_data']
    
    if form_data:
        # Determine if this is a draft or submission based on status
        is_draft = True
        if 'status' in review_data:
            is_draft = review_data['status'] == 'draft'
        else:
            # Check current review status if not being updated
            existing_review = service.get_review(review_id)
            if existing_review:
                is_draft = existing_review.status == 'draft'
        
        form_validation = validate_submission_completeness(form_data, is_draft=is_draft)
        if not form_validation.is_valid:
            raise HTTPException(
                status_code=400, 
                detail={
                    "error": "Form data validation failed",
                    "validation_errors": form_validation.errors,
                    "validation_warnings": form_validation.warnings,
                    "summary": get_validation_summary(form_validation)
                }
            )
        
        # Log warnings for monitoring
        if form_validation.warnings:
            logger.warning(f"Review update form validation warnings: {form_validation.warnings}")
    
    # Allow EA and ARB Admin to update any review
    if user_role in ['enterprise_architect', 'arb_admin']:
        service = ReviewService(db)
        review = service.update_review(review_id, review_data)
        if not review:
            raise HTTPException(status_code=404, detail="Review not found")
    # Allow Solution Architect to update their own draft reviews
    elif user_role == 'solution_architect':
        service = ReviewService(db)
        review = service.get_review(review_id)
        if not review:
            raise HTTPException(status_code=404, detail="Review not found")
        # Check if the review belongs to the current user and is in draft/submitted status
        if str(review.sa_user_id) != user_id_token:
            raise HTTPException(status_code=403, detail="You can only update your own reviews")
        if review.status not in ['draft', 'pending', 'submitted']:
            raise HTTPException(status_code=403, detail="You can only update draft or submitted reviews")
        review = service.update_review(review_id, review_data)
    else:
        raise HTTPException(status_code=403, detail="Only EA, ARB Admin, and Solution Architect can update reviews")
    
    return {
        "id": str(review.id),
        "created_at": review.created_at.isoformat() if review.created_at else None,
        "submitted_at": review.submitted_at.isoformat() if review.submitted_at else None,
        "reviewed_at": review.reviewed_at.isoformat() if review.reviewed_at else None,
        "sa_user_id": str(review.sa_user_id) if review.sa_user_id else None,
        "solution_name": review.solution_name,
        "scope_tags": review.scope_tags,
        "status": review.status,
        "decision": review.decision,
        "llm_model": review.llm_model,
        "tokens_used": review.tokens_used,
        "processing_time_ms": review.processing_time_ms,
        "llm_raw_response": review.llm_raw_response,
        "ea_user_id": str(review.ea_user_id) if review.ea_user_id else None,
        "ea_override_notes": review.ea_override_notes,
        "ea_overridden_at": review.ea_overridden_at.isoformat() if review.ea_overridden_at else None,
        "report_json": review.report_json,
        "validation_warnings": form_validation.warnings if 'form_data' in review_data else []
    }

@router.post("/{review_id}/approve")
async def approve_review(review_id: str, override_rationale: str = None, current_user: tuple = Depends(get_current_user), db: Session = Depends(get_db)):
    """Approve a review (EA approval) - EA and ARB Admin only"""
    user_id_token, user_role = current_user
    if not user_id_token:
        raise HTTPException(status_code=401, detail="Authentication required")
    if user_role not in ['enterprise_architect', 'arb_admin']:
        raise HTTPException(status_code=403, detail="Only EA and ARB Admin can approve reviews")
    service = ReviewService(db)
    review = service.approve_review(review_id, override_rationale)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    return {"message": "Review approved successfully", "review_id": review_id}

@router.post("/{review_id}/override")
async def override_review(review_id: str, decision: str, rationale: str, current_user: tuple = Depends(get_current_user), db: Session = Depends(get_db)):
    """Override agent recommendation (EA override) - EA and ARB Admin only"""
    user_id_token, user_role = current_user
    if not user_id_token:
        raise HTTPException(status_code=401, detail="Authentication required")
    if user_role not in ['enterprise_architect', 'arb_admin']:
        raise HTTPException(status_code=403, detail="Only EA and ARB Admin can override reviews")
    service = ReviewService(db)
    review = service.override_review(review_id, decision, rationale)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    return {"message": "Review overridden successfully", "review_id": review_id}
