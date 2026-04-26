from fastapi import APIRouter, HTTPException, Header, Depends
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from datetime import datetime
from app.core.database import get_db
from app.core.security import decode_access_token
from app.agents.enhanced_orchestrator import EnhancedARBOrchestrator
from app.services.review_service import ReviewService

router = APIRouter()

async def get_current_user(authorization: Optional[str] = Header(None)) -> Optional[str]:
    """Extract user ID from JWT token"""
    if not authorization:
        return None
    if not authorization.startswith("Bearer "):
        return None
    token = authorization.split(" ")[1]
    payload = decode_access_token(token)
    if not payload:
        return None
    return payload.get("sub")

@router.post("/review")
async def trigger_review(
    request: Dict[str, str],
    current_user: str = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Trigger ARB review orchestrator for a given review"""
    import logging
    logger = logging.getLogger(__name__)
    
    logger.info(f"[AGENT-ENDPOINT] Trigger review endpoint called by user: {current_user}")
    
    if not current_user:
        logger.error("[AGENT-ENDPOINT] Authentication required")
        raise HTTPException(status_code=401, detail="Authentication required")
    
    review_id = request.get("reviewId")
    if not review_id:
        logger.error("[AGENT-ENDPOINT] reviewId is required")
        raise HTTPException(status_code=400, detail="reviewId is required")
    
    logger.info(f"[AGENT-ENDPOINT] Starting ARB review for reviewId: {review_id}")
    
    try:
        # Initialize orchestrator
        orchestrator = EnhancedARBOrchestrator(db)
        
        # Run the review evaluation
        result = await orchestrator.run_review(
            review_id=review_id,
            checklist_data=await orchestrator.prepare_checklist_data(review_id)
        )
        
        logger.info(f"[AGENT-ENDPOINT] ARB review completed for reviewId: {review_id}, decision: {result.get('decision')}")
        
        # Persist review results to database
        try:
            from app.db.review_models import Review
            from sqlalchemy.orm import Session
            
            # Update review record
            review = db.query(Review).filter(Review.id == review_id).first()
            if review:
                review.decision = result.get("decision", "defer").lower().replace("_", "_")
                review.status = "pending"  # Waiting for EA review
                review.tokens_used = result.get("total_tokens_used", 0)
                review.processing_time_ms = int(result.get("processing_time_seconds", 0) * 1000)
                review.llm_model = result.get("llm_model", "gemini-2.5-flash-lite")
                review.report_json = result
                review.reviewed_at = datetime.utcnow()
                db.commit()
                logger.info(f"[AGENT-ENDPOINT] Review record updated with decision: {result.get('decision')}")
            
            # Create action items from recommendations
            if result.get("recommendations"):
                from app.db.review_models import Action
                for rec in result.get("recommendations", []):
                    action = Action(
                        review_id=review_id,
                        action_text=rec.get("action", ""),
                        owner_role=rec.get("owner", "Solution Architect"),
                        due_days=rec.get("timeline", "2 weeks"),
                        status="pending"
                    )
                    db.add(action)
                db.commit()
                logger.info(f"[AGENT-ENDPOINT] Created {len(result.get('recommendations', []))} action items")
            
            # Create ADRs from critical blockers/conditions
            if result.get("conditions"):
                from app.db.review_models import ADR
                for cond in result.get("conditions", []):
                    adr = ADR(
                        review_id=review_id,
                        adr_id=f"ADR-{review_id[:8]}",
                        decision="CONDITION",
                        rationale=cond.get("condition", ""),
                        target_date=cond.get("timeline", ""),
                        owner=cond.get("owner", ""),
                        status="pending"
                    )
                    db.add(adr)
                db.commit()
                logger.info(f"[AGENT-ENDPOINT] Created {len(result.get('conditions', []))} ADR items")
            
            # Save domain scores
            if result.get("domain_results"):
                from app.db.review_models import DomainScore
                for domain_slug, domain_data in result.get("domain_results", {}).items():
                    score = domain_data.get("compliance_score", 0)
                    domain_score = DomainScore(
                        review_id=review_id,
                        domain=domain_slug,
                        score=score
                    )
                    db.add(domain_score)
                    
                    # Save findings/gaps for this domain
                    if domain_data.get("gaps"):
                        from app.db.review_models import Finding
                        for gap in domain_data.get("gaps", []):
                            finding = Finding(
                                review_id=review_id,
                                domain=domain_slug,
                                principle_id=gap.get("reference_id", ""),
                                severity=gap.get("severity", "Medium").lower(),
                                finding=gap.get("description", ""),
                                recommendation="Review and address this gap",
                                is_resolved=False
                            )
                            db.add(finding)
                db.commit()
                logger.info(f"[AGENT-ENDPOINT] Saved domain scores and findings")
                
        except Exception as e:
            logger.error(f"[AGENT-ENDPOINT] Failed to persist review results: {e}")
            # Don't fail the request, just log the error
        
        return {
            "success": True,
            "reviewId": review_id,
            "decision": result.get("decision"),
            "report": result,
            "tokensUsed": result.get("total_tokens_used", 0)
        }
        
    except Exception as e:
        logger.error(f"[AGENT-ENDPOINT] Review orchestration failed: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Review orchestration failed: {str(e)}")

@router.post("/populate-knowledge-base")
async def populate_knowledge_base(current_user: str = Depends(get_current_user)):
    """Populate the knowledge base with sample EA standards"""
    if not current_user:
        raise HTTPException(status_code=401, detail="Authentication required")
    try:
        from app.services.knowledge_base import knowledge_base_service
        knowledge_base_service.populate_sample_knowledge()
        return {"message": "Knowledge base populated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error populating knowledge base: {str(e)}")

@router.get("/test-llm")
async def test_llm(current_user: str = Depends(get_current_user)):
    """Test LLM connectivity with a simple prompt"""
    import logging
    from app.services.llm_service import llm_service
    
    logger = logging.getLogger(__name__)
    logger.info("[TEST-LLM] Testing LLM connectivity")
    
    try:
        result = await llm_service.generate_completion(
            prompt="Say 'Hello from ARB AI Agent' and nothing else.",
            system_prompt="You are a test assistant.",
            temperature=0.1,
            max_tokens=100,
            timeout=30  # 30 second timeout for test
        )
        
        return {
            "success": True,
            "provider": result.get("provider"),
            "model": result.get("model"),
            "response": result.get("content"),
            "tokens_used": result.get("tokens_used")
        }
    except Exception as e:
        logger.error(f"[TEST-LLM] LLM test failed: {str(e)}")
        return {
            "success": False,
            "error": str(e),
            "provider": llm_service.provider
        }
