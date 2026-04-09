from fastapi import APIRouter, Depends, HTTPException
from typing import List
from datetime import datetime
from app.models.arb_submission import ARBReview, Decision

router = APIRouter()

# In-memory storage for demo (replace with database in production)
reviews_db = {}

@router.get("/")
async def get_reviews():
    """Get all ARB reviews"""
    return list(reviews_db.values())

@router.get("/{review_id}")
async def get_review(review_id: str):
    """Get a specific ARB review"""
    if review_id not in reviews_db:
        raise HTTPException(status_code=404, detail="Review not found")
    return reviews_db[review_id]

@router.get("/submission/{submission_id}")
async def get_review_by_submission(submission_id: str):
    """Get review for a specific submission"""
    for review in reviews_db.values():
        if review.submission_id == submission_id:
            return review
    raise HTTPException(status_code=404, detail="Review not found")

@router.post("/")
async def create_review(review: ARBReview):
    """Create a new ARB review"""
    review.id = f"review-{datetime.now().strftime('%Y%m%d%H%M%S')}"
    review.review_date = datetime.now()
    reviews_db[review.id] = review
    return review

@router.put("/{review_id}")
async def update_review(review_id: str, review: ARBReview):
    """Update an existing ARB review"""
    if review_id not in reviews_db:
        raise HTTPException(status_code=404, detail="Review not found")
    
    review.id = review_id
    reviews_db[review_id] = review
    return review

@router.post("/{review_id}/approve")
async def approve_review(review_id: str, override_rationale: str = None):
    """Approve a review (EA approval)"""
    if review_id not in reviews_db:
        raise HTTPException(status_code=404, detail="Review not found")
    
    review = reviews_db[review_id]
    review.ea_decision = Decision.APPROVE
    review.ea_override_rationale = override_rationale
    review.status = "approved"
    
    return {"message": "Review approved successfully", "review_id": review_id}

@router.post("/{review_id}/override")
async def override_review(review_id: str, decision: Decision, rationale: str):
    """Override agent recommendation (EA override)"""
    if review_id not in reviews_db:
        raise HTTPException(status_code=404, detail="Review not found")
    
    review = reviews_db[review_id]
    review.ea_decision = decision
    review.ea_override_rationale = rationale
    review.status = "overridden"
    
    return {"message": "Review overridden successfully", "review_id": review_id}
