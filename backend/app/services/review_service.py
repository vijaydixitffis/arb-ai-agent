from sqlalchemy.orm import Session
from app.db.review_models import Review
from typing import List, Optional
from datetime import datetime
import uuid


class ReviewService:
    """Service for review operations using database"""

    def __init__(self, db: Session):
        self.db = db

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
        """Create a new review"""
        review = Review(
            id=uuid.uuid4(),
            sa_user_id=uuid.UUID(review_data.get('sa_user_id')) if review_data.get('sa_user_id') else None,
            solution_name=review_data.get('solution_name'),
            scope_tags=review_data.get('scope_tags', []),
            artifact_path=review_data.get('artifact_path', ''),
            artifact_filename=review_data.get('artifact_filename', ''),
            artifact_file_type=review_data.get('artifact_file_type'),
            artifact_file_size_bytes=review_data.get('artifact_file_size_bytes'),
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

    def submit_review(self, review_id: str) -> Optional[Review]:
        """Submit a review for review"""
        try:
            review = self.db.query(Review).filter(Review.id == uuid.UUID(review_id)).first()
            if not review:
                return None
            
            review.status = 'submitted'
            review.submitted_at = datetime.utcnow()
            self.db.commit()
            self.db.refresh(review)
            return review
        except ValueError:
            return None

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
