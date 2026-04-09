from fastapi import APIRouter, HTTPException
from typing import Dict, Any
from app.agents.orchestrator import orchestrator

router = APIRouter()

@router.post("/review")
async def run_arb_review(submission_data: Dict[str, Any]):
    """Run AI agent ARB review pipeline"""
    try:
        submission_id = submission_data.get("submission_id")
        artefacts = submission_data.get("artefacts", [])
        domain_sections = submission_data.get("domain_sections", {})
        
        if not submission_id:
            raise HTTPException(status_code=400, detail="submission_id is required")
        
        # Run the orchestrator pipeline
        result = await orchestrator.run_review(
            submission_id=submission_id,
            artefacts=artefacts,
            domain_sections=domain_sections
        )
        
        return {
            "submission_id": submission_id,
            "status": "review_completed",
            "validation_results": result.get("validation_results"),
            "nfr_scores": result.get("nfr_scores"),
            "decision": result.get("decision"),
            "adrs": result.get("adrs"),
            "action_register": result.get("action_register")
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Review pipeline error: {str(e)}")

@router.post("/populate-knowledge-base")
async def populate_knowledge_base():
    """Populate the knowledge base with sample EA standards"""
    try:
        from app.services.knowledge_base import knowledge_base_service
        knowledge_base_service.populate_sample_knowledge()
        return {"message": "Knowledge base populated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error populating knowledge base: {str(e)}")
