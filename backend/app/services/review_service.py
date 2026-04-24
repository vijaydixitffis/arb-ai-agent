from sqlalchemy.orm import Session
from app.db.review_models import Review
from app.services.artefact_service import ArtefactService
from app.agents.enhanced_orchestrator import EnhancedARBOrchestrator
from typing import List, Optional, Dict, Any
from datetime import datetime
import uuid
import json


class ReviewService:
    """Service for review operations using database with multiple artefact support"""

    def __init__(self, db: Session):
        self.db = db
        self.artefact_service = ArtefactService(db)
        self.orchestrator = EnhancedARBOrchestrator(db)

    def get_all_reviews(self) -> List[Review]:
        """Get all reviews"""
        return self.db.query(Review).all()

    def get_review(self, review_id: str) -> Optional[Review]:
        """Get a specific review by ID"""
        try:
            return self.db.query(Review).filter(Review.id == uuid.UUID(review_id)).first()
        except ValueError:
            return None

    def get_reviews_by_user(self, user_id: str) -> List[Review]:
        """Get reviews by SA user ID"""
        try:
            return self.db.query(Review).filter(Review.sa_user_id == uuid.UUID(user_id)).all()
        except ValueError:
            return []

    def get_reviews_by_status(self, status: str) -> List[Review]:
        """Get reviews by status"""
        return self.db.query(Review).filter(Review.status == status).all()

    def create_review(self, review_data: dict) -> Review:
        """Create a new review (without artefacts - artefacts uploaded separately)"""
        review = Review(
            id=uuid.uuid4(),
            sa_user_id=uuid.UUID(review_data.get('sa_user_id')) if review_data.get('sa_user_id') else None,
            solution_name=review_data.get('solution_name'),
            scope_tags=review_data.get('scope_tags', []),
            status=review_data.get('status', 'draft'),
            report_json=review_data.get('report_json')
        )
        self.db.add(review)
        self.db.commit()
        self.db.refresh(review)
        return review

    def update_review(self, review_id: str, review_data: dict) -> Optional[Review]:
        """Update an existing review"""
        try:
            review = self.db.query(Review).filter(Review.id == uuid.UUID(review_id)).first()
            if not review:
                return None
            
            for key, value in review_data.items():
                if hasattr(review, key) and value is not None:
                    setattr(review, key, value)
            
            review.updated_at = datetime.utcnow()
            self.db.commit()
            self.db.refresh(review)
            return review
        except ValueError:
            return None

    async def submit_review(self, review_id: str) -> Optional[Review]:
        """Submit a review for ARB evaluation"""
        try:
            review = self.db.query(Review).filter(Review.id == uuid.UUID(review_id)).first()
            if not review:
                return None
            
            # Check if review has artefacts
            artefacts = await self.artefact_service.get_artefacts_by_review(str(review.id))
            if not artefacts:
                raise ValueError("Cannot submit review without artefacts")
            
            review.status = 'submitted'
            review.submitted_at = datetime.utcnow()
            self.db.commit()
            self.db.refresh(review)
            return review
        except ValueError:
            return None

    async def run_review_evaluation(self, review_id: str) -> Dict[str, Any]:
        """Run ARB evaluation using enhanced orchestrator"""
        try:
            # Prepare checklist data
            checklist_data = await self.orchestrator.prepare_checklist_data(review_id)
            
            # Run the review
            result = await self.orchestrator.run_review(
                review_id=review_id,
                checklist_data=checklist_data
            )
            
            # Update review with results
            review = self.db.query(Review).filter(Review.id == uuid.UUID(review_id)).first()
            if review:
                review.status = 'reviewed'
                review.decision = result.get('decision')
                review.report_json = result
                review.tokens_used = result.get('total_tokens_used')
                review.reviewed_at = datetime.utcnow()
                self.db.commit()
            
            return result
        except Exception as e:
            # Update review with error status
            review = self.db.query(Review).filter(Review.id == uuid.UUID(review_id)).first()
            if review:
                review.status = 'error'
                review.report_json = {"error": str(e)}
                self.db.commit()
            raise

    def approve_review(self, review_id: str, override_rationale: Optional[str] = None) -> Optional[Review]:
        """Approve a review (EA approval)"""
        try:
            review = self.db.query(Review).filter(Review.id == uuid.UUID(review_id)).first()
            if not review:
                return None
            
            review.status = 'approved'
            review.decision = 'approve'
            review.ea_override_notes = override_rationale
            review.ea_overridden_at = datetime.utcnow()
            review.reviewed_at = datetime.utcnow()
            self.db.commit()
            self.db.refresh(review)
            return review
        except ValueError:
            return None

    def override_review(self, review_id: str, decision: str, rationale: str) -> Optional[Review]:
        """Override agent recommendation (EA override)"""
        try:
            review = self.db.query(Review).filter(Review.id == uuid.UUID(review_id)).first()
            if not review:
                return None
            
            review.status = 'overridden'
            review.decision = decision
            review.ea_override_notes = rationale
            review.ea_overridden_at = datetime.utcnow()
            review.reviewed_at = datetime.utcnow()
            self.db.commit()
            self.db.refresh(review)
            return review
        except ValueError:
            return None

    async def get_review_summary(self, review_id: str) -> Dict[str, Any]:
        """Get comprehensive review summary including artefacts"""
        return await self.orchestrator.get_review_summary(review_id)

    def extract_scope_tags(self, review_data: Dict[str, Any]) -> List[str]:
        """Extract scope tags from review data (dynamic based on domains)"""
        scope_tags = []
        
        # Extract from domain_data if present
        domain_data = review_data.get("domain_data", {})
        for domain_slug, domain_info in domain_data.items():
            if domain_info:  # Domain has data
                scope_tags.append(domain_slug)
        
        # Extract from legacy fields if present
        if "scope_tags" in review_data:
            scope_tags.extend(review_data["scope_tags"])
        
        # Remove duplicates and return
        return list(set(scope_tags))
