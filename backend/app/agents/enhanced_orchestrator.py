from sqlalchemy.orm import Session
from typing import Dict, Any, List, Optional
import asyncio
import logging
import time
from app.agents.enhanced_domain_agents import EnhancedDomainValidationAgent
from app.services.artefact_service import ArtefactService
from app.db.review_models import Review
from app.db.metadata_models import Domain, ChecklistQuestion
import json

logger = logging.getLogger(__name__)

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
        
        start_time = time.time()
        logger.info(f"[ARB-ORCHESTRATOR] Starting ARB review for: {review_id}")
        
        # Get review details
        logger.info(f"[ARB-ORCHESTRATOR] Fetching review details for: {review_id}")
        review = self.db.query(Review).filter(Review.id == review_id).first()
        if not review:
            logger.error(f"[ARB-ORCHESTRATOR] Review {review_id} not found")
            raise ValueError(f"Review {review_id} not found")
        
        logger.info(f"[ARB-ORCHESTRATOR] Review found - Solution: {review.solution_name}, Status: {review.status}, Scope Tags: {review.scope_tags}")
        
        # Get domains to evaluate based on scope tags
        domains_to_evaluate = self._get_domains_from_scope(review.scope_tags)
        logger.info(f"[ARB-ORCHESTRATOR] Domains to evaluate: {domains_to_evaluate}")
        
        # Get artefacts for context
        artefacts = await self.artefact_service.get_artefacts_by_review(review_id)
        logger.info(f"[ARB-ORCHESTRATOR] Total artefacts found: {len(artefacts)}")
        for artefact in artefacts:
            logger.debug(f"[ARB-ORCHESTRATOR] Artefact: {artefact.get('artefact_name')} (Domain: {artefact.get('domain_slug')}, Type: {artefact.get('artefact_type')})")
        
        # Run domain validation in parallel
        logger.info(f"[ARB-ORCHESTRATOR] Starting parallel domain validation for {len(domains_to_evaluate)} domains")
        domain_start_time = time.time()
        domain_results = await self._run_domain_validations(
            review_id=review_id,
            domains=domains_to_evaluate,
            checklist_data=checklist_data
        )
        domain_duration = time.time() - domain_start_time
        logger.info(f"[ARB-ORCHESTRATOR] Domain validation completed in {domain_duration:.2f}s")
        
        # Log domain results summary
        for result in domain_results:
            logger.info(f"[ARB-ORCHESTRATOR] Domain {result.get('domain')}: Compliance={result.get('overall_compliance')}, Score={result.get('compliance_score')}, Tokens={result.get('tokens_used')}, Gaps={len(result.get('gaps', []))}")
        
        # Synthesize results into final decision
        logger.info(f"[ARB-ORCHESTRATOR] Starting synthesis of domain results")
        synthesis_start_time = time.time()
        final_result = await self.domain_agent.synthesize_domain_results(
            review_id=review_id,
            domain_results=domain_results
        )
        synthesis_duration = time.time() - synthesis_start_time
        logger.info(f"[ARB-ORCHESTRATOR] Synthesis completed in {synthesis_duration:.2f}s")
        
        # Add comprehensive metadata
        total_duration = time.time() - start_time
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
                "llm_calls_made": len(domains_to_evaluate) + 1,  # Domain calls + synthesis
                "total_duration_seconds": total_duration,
                "domain_validation_duration_seconds": domain_duration,
                "synthesis_duration_seconds": synthesis_duration
            }
        })
        
        logger.info(f"[ARB-ORCHESTRATOR] ARB review completed - Decision: {final_result.get('decision')}, Total Duration: {total_duration:.2f}s, Total Tokens: {final_result.get('total_tokens_used')}")
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
        
        logger.info(f"[ARB-ORCHESTRATOR] Creating validation tasks for {len(domains)} domains")
        
        # Create tasks for parallel execution
        tasks = []
        for domain_slug in domains:
            logger.debug(f"[ARB-ORCHESTRATOR] Preparing validation task for domain: {domain_slug}")
            # Get domain-specific checklist data
            domain_checklist = checklist_data.get("domain_data", {}).get(domain_slug, {})
            domain_checklist["domain_metadata"] = self._get_domain_metadata(domain_slug)
            logger.debug(f"[ARB-ORCHESTRATOR] Domain {domain_slug} checklist items: {len(domain_checklist.get('checklist_items', []))}")
            
            task = self.domain_agent.validate_domain(
                review_id=review_id,
                domain_slug=domain_slug,
                checklist_data=domain_checklist
            )
            tasks.append(task)
        
        # Execute all domain validations in parallel
        logger.info(f"[ARB-ORCHESTRATOR] Executing {len(tasks)} domain validation tasks in parallel")
        domain_results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Process results and handle exceptions
        processed_results = []
        for i, result in enumerate(domain_results):
            domain_slug = domains[i]
            
            if isinstance(result, Exception):
                # Handle validation errors
                logger.error(f"[ARB-ORCHESTRATOR] Domain {domain_slug} validation failed: {str(result)}")
                processed_results.append({
                    "domain": domain_slug,
                    "overall_compliance": "NON_COMPLIANT",
                    "compliance_score": 0,
                    "gaps": [{"description": f"Validation error: {str(result)}", "severity": "Critical"}],
                    "recommendations": ["Manual review required due to validation error"],
                    "error": str(result)
                })
            else:
                logger.debug(f"[ARB-ORCHESTRATOR] Domain {domain_slug} validation completed successfully")
                processed_results.append(result)
        
        logger.info(f"[ARB-ORCHESTRATOR] Processed {len(processed_results)} domain results")
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
        """Prepare checklist data for review from stored form data in report_json"""
        
        # Fetch review from database
        review = self.db.query(Review).filter(Review.id == review_id).first()
        if not review or not review.report_json:
            logger.warning(f"[ORCHESTRATOR] No report_json found for review {review_id}, returning empty checklist data")
            return {"domain_data": {}}
        
        form_data = review.report_json.get("form_data", {})
        domain_data_result = {}
        
        # Build a cache of question codes to question text for lookup
        all_questions = self.db.query(ChecklistQuestion).all()
        question_text_cache = {q.question_code: q.question_text for q in all_questions}
        logger.info(f"[ORCHESTRATOR] Loaded {len(question_text_cache)} questions from metadata")
        
        # Process new format: domain_data.{domain}.checklist
        if "domain_data" in form_data:
            for domain, data in form_data["domain_data"].items():
                checklist_items = []
                checklist = data.get("checklist", {})
                evidence = data.get("evidence", {})
                
                for question_code, answer in checklist.items():
                    question_text = question_text_cache.get(question_code, f"Unknown question: {question_code}")
                    checklist_items.append({
                        "question_code": question_code,
                        "question_text": question_text,
                        "answer": answer,
                        "evidence": evidence.get(question_code, "")
                    })
                
                if checklist_items:
                    domain_data_result[domain] = {"checklist_items": checklist_items}
        
        # Process old format: {domain}_checklist (backward compatibility)
        for key, value in form_data.items():
            if key.endswith("_checklist") and isinstance(value, dict):
                domain = key.replace("_checklist", "")
                evidence_key = f"{domain}_evidence"
                evidence_data = form_data.get(evidence_key, {})
                
                # Merge with existing or create new
                if domain not in domain_data_result:
                    domain_data_result[domain] = {"checklist_items": []}
                
                existing_codes = {item["question_code"] for item in domain_data_result[domain]["checklist_items"]}
                
                for question_code, answer in value.items():
                    if question_code not in existing_codes:
                        question_text = question_text_cache.get(question_code, f"Unknown question: {question_code}")
                        domain_data_result[domain]["checklist_items"].append({
                            "question_code": question_code,
                            "question_text": question_text,
                            "answer": answer,
                            "evidence": evidence_data.get(question_code, "")
                        })
        
        logger.info(f"[ORCHESTRATOR] Prepared checklist data for {len(domain_data_result)} domains from report_json")
        for domain, data in domain_data_result.items():
            logger.info(f"[ORCHESTRATOR]   - {domain}: {len(data['checklist_items'])} checklist items")
        
        return {"domain_data": domain_data_result}
