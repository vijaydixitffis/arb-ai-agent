from sqlalchemy.orm import Session
from typing import Dict, Any, List, Optional
import asyncio
from app.agents.enhanced_domain_agents import EnhancedDomainValidationAgent
from app.services.artefact_service import ArtefactService
from app.db.review_models import Review
from app.db.metadata_models import Domain
import json

class EnhancedARBOrchestrator:
    """Enhanced ARB orchestrator using PostgreSQL artefact storage and domain-wise LLM calls"""
    
    def __init__(self, db: Session):
        self.db = db
        self.domain_agent = EnhancedDomainValidationAgent(db)
        self.artefact_service = ArtefactService(db)
    
    async def run_review(
        self, 
        review_id: str,
        checklist_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Run complete ARB review with domain-wise validation and synthesis"""
        
        print(f"Starting ARB review for: {review_id}")
        
        # Get review details
        review = self.db.query(Review).filter(Review.id == review_id).first()
        if not review:
            raise ValueError(f"Review {review_id} not found")
        
        # Get domains to evaluate based on scope tags
        domains_to_evaluate = self._get_domains_from_scope(review.scope_tags)
        
        # Run domain validation in parallel
        domain_results = await self._run_domain_validations(
            review_id=review_id,
            domains=domains_to_evaluate,
            checklist_data=checklist_data
        )
        
        # Synthesize results into final decision
        final_result = await self.domain_agent.synthesize_domain_results(
            review_id=review_id,
            domain_results=domain_results
        )
        
        # Add comprehensive metadata
        final_result.update({
            "review_id": review_id,
            "solution_name": review.solution_name,
            "scope_tags": review.scope_tags,
            "domains_evaluated": [r.get("domain") for r in domain_results],
            "total_tokens_used": sum(r.get("tokens_used", 0) for r in domain_results) + final_result.get("tokens_used", 0),
            "domain_results": domain_results,
            "review_metadata": {
                "total_artefacts": len(await self.artefact_service.get_artefacts_by_review(review_id)),
                "total_chunks": len(await self.artefact_service.get_relevant_chunks(review_id)),
                "llm_calls_made": len(domains_to_evaluate) + 1  # Domain calls + synthesis
            }
        })
        
        return final_result
    
    def _get_domains_from_scope(self, scope_tags: List[str]) -> List[str]:
        """Map scope tags to domain slugs"""
        # Get all active domains from database
        domains = self.db.query(Domain).filter(Domain.is_active == True).all()
        domain_map = {d.slug: d for d in domains}
        
        # Map scope tags to domain slugs
        domains_to_evaluate = []
        for tag in scope_tags:
            if tag in domain_map:
                domains_to_evaluate.append(tag)
        
        # Always include general domain if present
        if "general" in domain_map and "general" not in domains_to_evaluate:
            domains_to_evaluate.append("general")
        
        return domains_to_evaluate
    
    async def _run_domain_validations(
        self,
        review_id: str,
        domains: List[str],
        checklist_data: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Run domain validations in parallel"""
        
        # Create tasks for parallel execution
        tasks = []
        for domain_slug in domains:
            # Get domain-specific checklist data
            domain_checklist = checklist_data.get("domain_data", {}).get(domain_slug, {})
            domain_checklist["domain_metadata"] = self._get_domain_metadata(domain_slug)
            
            task = self.domain_agent.validate_domain(
                review_id=review_id,
                domain_slug=domain_slug,
                checklist_data=domain_checklist
            )
            tasks.append(task)
        
        # Execute all domain validations in parallel
        domain_results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Process results and handle exceptions
        processed_results = []
        for i, result in enumerate(domain_results):
            domain_slug = domains[i]
            
            if isinstance(result, Exception):
                # Handle validation errors
                processed_results.append({
                    "domain": domain_slug,
                    "overall_compliance": "NON_COMPLIANT",
                    "compliance_score": 0,
                    "gaps": [{"description": f"Validation error: {str(result)}", "severity": "Critical"}],
                    "recommendations": ["Manual review required due to validation error"],
                    "error": str(result)
                })
            else:
                processed_results.append(result)
        
        return processed_results
    
    def _get_domain_metadata(self, domain_slug: str) -> Dict[str, Any]:
        """Get metadata for a domain"""
        domain = self.db.query(Domain).filter(
            Domain.slug == domain_slug,
            Domain.is_active == True
        ).first()
        
        if not domain:
            return {"name": domain_slug.title(), "description": ""}
        
        return {
            "name": domain.name,
            "description": domain.description or "",
            "color": domain.color,
            "icon": domain.icon,
            "seq_number": domain.seq_number
        }
    
    async def get_review_summary(self, review_id: str) -> Dict[str, Any]:
        """Get summary of review status and progress"""
        
        # Get review details
        review = self.db.query(Review).filter(Review.id == review_id).first()
        if not review:
            raise ValueError(f"Review {review_id} not found")
        
        # Get artefacts
        artefacts = await self.artefact_service.get_artefacts_by_review(review_id)
        
        # Group artefacts by domain
        artefacts_by_domain = {}
        for artefact in artefacts:
            domain = artefact["domain_slug"]
            if domain not in artefacts_by_domain:
                artefacts_by_domain[domain] = []
            artefacts_by_domain[domain].append(artefact)
        
        return {
            "review_id": review_id,
            "solution_name": review.solution_name,
            "status": review.status,
            "decision": review.decision,
            "scope_tags": review.scope_tags,
            "submitted_at": review.submitted_at,
            "reviewed_at": review.reviewed_at,
            "total_artefacts": len(artefacts),
            "artefacts_by_domain": artefacts_by_domain,
            "domains_ready": list(artefacts_by_domain.keys())
        }
    
    async def prepare_checklist_data(self, review_id: str) -> Dict[str, Any]:
        """Prepare checklist data for review from stored form data"""
        
        # This would typically fetch from a form_data table or similar
        # For now, return a basic structure
        return {
            "domain_data": {
                "general": {
                    "checklist_items": [
                        {
                            "question_text": "Business stakeholders identified and engaged?",
                            "answer": "Yes",
                            "evidence": "Stakeholder register attached"
                        }
                    ]
                },
                "application": {
                    "checklist_items": [
                        {
                            "question_text": "Application inventory complete?",
                            "answer": "Yes",
                            "evidence": "Application portfolio document"
                        }
                    ]
                },
                "integration": {
                    "checklist_items": [
                        {
                            "question_text": "Integration catalogue complete?",
                            "answer": "Partial",
                            "evidence": "Some integrations documented"
                        }
                    ]
                },
                "data": {
                    "checklist_items": [
                        {
                            "question_text": "Data classification performed?",
                            "answer": "Yes",
                            "evidence": "Data classification matrix"
                        }
                    ]
                },
                "security": {
                    "checklist_items": [
                        {
                            "question_text": "Security assessment completed?",
                            "answer": "Yes",
                            "evidence": "Security assessment report"
                        }
                    ]
                },
                "infrastructure": {
                    "checklist_items": [
                        {
                            "question_text": "Infrastructure architecture documented?",
                            "answer": "Yes",
                            "evidence": "Infrastructure diagrams"
                        }
                    ]
                },
                "devsecops": {
                    "checklist_items": [
                        {
                            "question_text": "CI/CD pipeline defined?",
                            "answer": "Partial",
                            "evidence": "Pipeline documentation in progress"
                        }
                    ]
                },
                "nfr": {
                    "checklist_items": [
                        {
                            "question_text": "Performance requirements defined?",
                            "answer": "Yes",
                            "evidence": "NFR specification document"
                        }
                    ]
                }
            }
        }
