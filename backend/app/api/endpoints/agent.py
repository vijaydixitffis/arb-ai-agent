from fastapi import APIRouter, HTTPException, Header, Depends
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
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
    if not current_user:
        raise HTTPException(status_code=401, detail="Authentication required")
    
    review_id = request.get("reviewId")
    if not review_id:
        raise HTTPException(status_code=400, detail="reviewId is required")
    
    try:
        # Initialize orchestrator
        orchestrator = EnhancedARBOrchestrator(db)
        
        # Run the review evaluation
        result = await orchestrator.run_review(
            review_id=review_id,
            checklist_data=await orchestrator.prepare_checklist_data(review_id)
        )
        
        return {
            "success": True,
            "reviewId": review_id,
            "decision": result.get("decision"),
            "report": result,
            "tokensUsed": result.get("total_tokens_used", 0)
        }
        
    except Exception as e:
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
