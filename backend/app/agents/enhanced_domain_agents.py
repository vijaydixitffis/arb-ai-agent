from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session
import logging
import time
from app.services.llm_service import llm_service
from app.services.artefact_service import ArtefactService
from app.db.review_models import Review
import json

logger = logging.getLogger(__name__)

class EnhancedDomainValidationAgent:
    """Enhanced domain agent using PostgreSQL artefact chunks and knowledge base"""
    
    def __init__(self, db: Session):
        self.db = db
        self.llm_service = llm_service
        self.artefact_service = ArtefactService(db)
        
        # Domain-specific system prompts
        self.domain_prompts = {
            "general": "You are an expert Enterprise Architecture validator for General/Enterprise Architecture. Focus on overall architecture governance, stakeholder alignment, and architectural decision records.",
            "business": "You are a Business Architecture expert. Validate business capabilities, value streams, stakeholder requirements, and business process alignment.",
            "application": "You are an Application Architecture expert. Focus on application portfolio, API design, microservices, integration patterns, and technology standards.",
            "integration": "You are an Integration Architecture expert. Validate API gateways, message brokers, data exchange patterns, and system interoperability.",
            "data": "You are a Data Architecture expert. Focus on data models, lineage, governance, master data, and data quality standards.",
            "security": "You are a Security Architecture expert. Validate authentication, authorization, encryption, security controls, and compliance requirements.",
            "infrastructure": "You are an Infrastructure Architecture expert. Focus on cloud infrastructure, scalability, reliability, monitoring, and operations.",
            "devsecops": "You are a DevSecOps expert. Validate CI/CD pipelines, security automation, DevOps practices, and operational readiness.",
            "nfr": "You are a Non-Functional Requirements expert. Validate performance, scalability, availability, disaster recovery, and service level agreements."
        }
    
    async def validate_domain(
        self,
        review_id: str,
        domain_slug: str,
        checklist_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Validate a specific domain using artefact chunks and knowledge base"""
        
        start_time = time.time()
        logger.info(f"[DOMAIN-AGENT] Starting validation for domain: {domain_slug}, review: {review_id}")
        
        # Get relevant artefact chunks for this domain
        logger.debug(f"[DOMAIN-AGENT] Fetching artefact chunks for domain: {domain_slug}")
        chunks_start = time.time()
        artefact_chunks = await self.artefact_service.get_relevant_chunks(
            review_id=review_id,
            domain_slug=domain_slug,
            limit=20
        )
        chunks_duration = time.time() - chunks_start
        logger.info(f"[DOMAIN-AGENT] Retrieved {len(artefact_chunks)} artefact chunks in {chunks_duration:.2f}s")
        for i, chunk in enumerate(artefact_chunks[:5]):  # Log first 5 chunks
            logger.debug(f"[DOMAIN-AGENT] Chunk {i+1}: {chunk.get('filename')} (length: {len(chunk.get('chunk_text', ''))} chars)")
        
        # Get relevant knowledge base content
        logger.debug(f"[DOMAIN-AGENT] Searching knowledge base for domain: {domain_slug}")
        kb_start = time.time()
        kb_results = await self.artefact_service.search_knowledge_base(
            query=f"{domain_slug} architecture principles standards",
            category=domain_slug,
            limit=10
        )
        
        # Also get general principles
        general_kb = await self.artefact_service.search_knowledge_base(
            query="general enterprise architecture principles",
            category="general",
            limit=5
        )
        kb_results.extend(general_kb)

        # Include EA patterns reference material relevant to this domain
        ea_patterns_kb = await self.artefact_service.search_knowledge_base(
            query=f"{domain_slug} architecture patterns",
            category="ea-patterns",
            limit=5
        )
        kb_results.extend(ea_patterns_kb)
        kb_duration = time.time() - kb_start
        logger.info(f"[DOMAIN-AGENT] Retrieved {len(kb_results)} knowledge base articles in {kb_duration:.2f}s")
        for kb in kb_results[:3]:  # Log first 3 KB articles
            logger.debug(f"[DOMAIN-AGENT] KB Article: {kb.get('title')} (Principle: {kb.get('principle_id', 'N/A')})")
        
        # Build domain-specific prompt
        logger.debug(f"[DOMAIN-AGENT] Building domain prompt")
        prompt = await self._build_domain_prompt(
            domain_slug=domain_slug,
            artefact_chunks=artefact_chunks,
            knowledge_base=kb_results,
            checklist_data=checklist_data
        )
        logger.debug(f"[DOMAIN-AGENT] Prompt length: {len(prompt)} chars")
        
        # Log prompt to file for testing
        import os
        prompt_file = f"/tmp/llm_prompt_{domain_slug}_{review_id[:8]}.txt"
        with open(prompt_file, 'w') as f:
            f.write(f"SYSTEM PROMPT:\n{self.domain_prompts.get(domain_slug, self.domain_prompts['general'])}\n\n")
            f.write(f"USER PROMPT:\n{prompt}")
        logger.info(f"[DOMAIN-AGENT] Prompt saved to: {prompt_file}")
        
        # Call LLM
        logger.info(f"[DOMAIN-AGENT] Calling LLM for domain: {domain_slug}")
        llm_start = time.time()
        response = await self.llm_service.generate_completion(
            prompt=prompt,
            system_prompt=self.domain_prompts.get(domain_slug, self.domain_prompts["general"]),
            temperature=0.1,
            max_tokens=4000
        )
        llm_duration = time.time() - llm_start
        logger.info(f"[DOMAIN-AGENT] LLM call completed in {llm_duration:.2f}s, Tokens used: {response.get('tokens_used', 'N/A')}")
        logger.debug(f"[DOMAIN-AGENT] LLM response length: {len(response.get('content', ''))} chars")
        
        # Clean markdown code blocks if present
        content = response["content"]
        if content.strip().startswith("```"):
            content = content.strip()
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]
            content = content.strip()
        
        # Parse response
        try:
            result = json.loads(content)
            logger.info(f"[DOMAIN-AGENT] Successfully parsed LLM response for domain: {domain_slug}")
        except json.JSONDecodeError as e:
            logger.error(f"[DOMAIN-AGENT] Failed to parse LLM response as JSON: {e}")
            logger.debug(f"[DOMAIN-AGENT] Raw response: {content[:500]}...")
            raise
        
        # Add metadata
        result["tokens_used"] = response["tokens_used"]
        result["artefact_chunks_used"] = len(artefact_chunks)
        result["kb_articles_used"] = len(kb_results)
        
        total_duration = time.time() - start_time
        logger.info(f"[DOMAIN-AGENT] Domain validation completed - Domain: {domain_slug}, Compliance: {result.get('overall_compliance')}, Score: {result.get('compliance_score')}, Gaps: {len(result.get('gaps', []))}, Total Duration: {total_duration:.2f}s")
        
        return result
    
    async def _build_domain_prompt(
        self,
        domain_slug: str,
        artefact_chunks: List[Dict[str, Any]],
        knowledge_base: List[Dict[str, Any]],
        checklist_data: Dict[str, Any]
    ) -> str:
        """Build comprehensive prompt for domain validation"""
        
        # Format artefact chunks
        artefacts_text = ""
        for i, chunk in enumerate(artefact_chunks[:15], 1):  # Limit to top 15 chunks
            artefacts_text += f"\n--- Artefact Chunk {i} ({chunk.get('filename', 'Unknown')}) ---\n"
            artefacts_text += chunk["chunk_text"] + "\n"
        
        # Format knowledge base
        kb_text = ""
        for i, kb in enumerate(knowledge_base[:10], 1):  # Limit to top 10 KB articles
            kb_text += f"\n--- Knowledge Base {i}: {kb['title']} ---\n"
            if kb.get('principle_id'):
                kb_text += f"Principle ID: {kb['principle_id']}\n"
            kb_text += kb["content"] + "\n"
        
        # Format checklist
        checklist_text = ""
        checklist_items = checklist_data.get("checklist_items", [])
        for item in checklist_items:
            question = item.get('question_text', item.get('question', 'N/A'))
            answer = item.get('answer', 'N/A')
            evidence = item.get('evidence_notes', item.get('evidence', 'None'))
            checklist_text += f"- Q: {question}\n  A: {answer}\n  Evidence: {evidence}\n\n"
        
        # Get domain metadata
        domain_metadata = checklist_data.get("domain_metadata", {})
        domain_name = domain_metadata.get("name", domain_slug.title())
        domain_description = domain_metadata.get("description", "")
        
        prompt = f"""You are conducting an Enterprise Architecture Review Board (ARB) validation for the {domain_name} domain.

Domain Description: {domain_description}

=== RELEVANT ARTEFACT CONTENT ===
{artefacts_text if artefacts_text else "No artefact content available for this domain."}

=== RELEVANT KNOWLEDGE BASE ===
{kb_text if kb_text else "No relevant knowledge base articles found."}

=== COMPLIANCE CHECKLIST ===
{checklist_text if checklist_text else "No checklist items provided."}

=== VALIDATION TASK ===
Based on the artefact content, knowledge base principles/standards, and checklist responses:

1. Analyze the submitted artefacts for {domain_name} domain compliance
2. Reference specific principle IDs from the knowledge base in your findings
3. Identify gaps between submitted artefacts and required standards
4. Evaluate the quality and completeness of checklist evidence
5. Provide specific, actionable recommendations

=== RESPONSE FORMAT ===
Provide your analysis in this exact JSON format:
{{
    "domain": "{domain_slug}",
    "domain_name": "{domain_name}",
    "overall_compliance": "COMPLIANT|PARTIALLY_COMPLIANT|NON_COMPLIANT",
    "compliance_score": 0-100,
    "checklist_compliance": {{
        "total_items": number,
        "compliant_items": number,
        "non_compliant_items": number,
        "partial_items": number
    }},
    "gaps": [
        {{
            "type": "principle|standard|checklist|evidence",
            "reference_id": "PRINCIPLE-XX or STANDARD-XX or checklist_item_id",
            "description": "Clear description of the gap",
            "severity": "Critical|High|Medium|Low",
            "artefact_reference": "filename or section where gap was found"
        }}
    ],
    "recommendations": [
        {{
            "action": "Specific action to take",
            "priority": "Critical|High|Medium|Low",
            "owner": "Role responsible for action"
        }}
    ],
    "violated_principles": ["PRINCIPLE-XX", "PRINCIPLE-YY"],
    "evidence_gaps": ["Missing evidence for checklist item X"],
    "strengths": ["What was done well in this domain"],
    "next_steps": ["Immediate next steps for the team"]
}}

Focus on providing specific, evidence-based findings with clear references to the artefact content and knowledge base principles."""
        
        return prompt
    
    async def synthesize_domain_results(
        self,
        review_id: str,
        domain_results: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Synthesize all domain results into final ARB recommendation"""
        
        start_time = time.time()
        logger.info(f"[DOMAIN-AGENT] Starting synthesis of {len(domain_results)} domain results for review: {review_id}")
        
        # Get overall review context
        logger.debug(f"[DOMAIN-AGENT] Fetching review context for synthesis")
        review = self.db.query(Review).filter(Review.id == review_id).first()
        if not review:
            logger.error(f"[DOMAIN-AGENT] Review {review_id} not found for synthesis")
            raise ValueError(f"Review {review_id} not found")
        
        logger.info(f"[DOMAIN-AGENT] Review context - Solution: {review.solution_name}, Scope: {review.scope_tags}")
        
        # Get all artefact chunks for context
        logger.debug(f"[DOMAIN-AGENT] Fetching artefact chunks for synthesis context")
        chunks_start = time.time()
        all_chunks = await self.artefact_service.get_relevant_chunks(
            review_id=review_id,
            limit=50
        )
        chunks_duration = time.time() - chunks_start
        logger.info(f"[DOMAIN-AGENT] Retrieved {len(all_chunks)} artefact chunks for synthesis in {chunks_duration:.2f}s")
        
        # Build synthesis prompt
        logger.debug(f"[DOMAIN-AGENT] Building synthesis prompt")
        prompt = self._build_synthesis_prompt(
            review=review,
            domain_results=domain_results,
            artefact_chunks=all_chunks
        )
        logger.debug(f"[DOMAIN-AGENT] Synthesis prompt length: {len(prompt)} chars")
        
        # Log synthesis prompt to file for testing
        synthesis_prompt_file = f"/tmp/llm_prompt_synthesis_{review_id[:8]}.txt"
        with open(synthesis_prompt_file, 'w') as f:
            f.write(f"SYSTEM PROMPT:\nYou are the Chief Architecture Review Board member responsible for synthesizing domain evaluations into a final ARB decision.\n\n")
            f.write(f"USER PROMPT:\n{prompt}")
        logger.info(f"[DOMAIN-AGENT] Synthesis prompt saved to: {synthesis_prompt_file}")
        
        # Call LLM for synthesis
        logger.info(f"[DOMAIN-AGENT] Calling LLM for synthesis")
        llm_start = time.time()
        response = await self.llm_service.generate_completion(
            prompt=prompt,
            system_prompt="You are the Chief Architecture Review Board member responsible for synthesizing domain evaluations into a final ARB decision.",
            temperature=0.1,
            max_tokens=4000
        )
        llm_duration = time.time() - llm_start
        content = response.get("content", "")
        logger.info(f"[DOMAIN-AGENT] LLM synthesis call completed in {llm_duration:.2f}s, Tokens used: {response.get('tokens_used', 'N/A')}, Content length: {len(content) if content else 0}")
        
        # Log raw response for debugging
        if content:
            logger.info(f"[DOMAIN-AGENT] Raw response preview: {content[:200]}...")
        else:
            logger.error(f"[DOMAIN-AGENT] LLM response content is EMPTY! Full response: {response}")
        
        # Clean markdown code blocks if present
        if content.strip().startswith("```"):
            # Remove opening ```json or ```
            content = content.strip()
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            # Remove closing ```
            if content.endswith("```"):
                content = content[:-3]
            content = content.strip()
            logger.info(f"[DOMAIN-AGENT] Stripped markdown code blocks, new content length: {len(content)}")
        
        # Parse response
        try:
            result = json.loads(content)
            logger.info(f"[DOMAIN-AGENT] Successfully parsed synthesis response - Decision: {result.get('decision')}")
        except json.JSONDecodeError as e:
            logger.error(f"[DOMAIN-AGENT] Failed to parse synthesis response as JSON: {e}")
            logger.error(f"[DOMAIN-AGENT] Raw response content: {content[:1000] if content else 'EMPTY'}")
            raise
        
        # Add metadata
        result["tokens_used"] = response["tokens_used"]
        result["domains_evaluated"] = len(domain_results)
        
        total_duration = time.time() - start_time
        logger.info(f"[DOMAIN-AGENT] Synthesis completed - Decision: {result.get('decision')}, Aggregate Score: {result.get('aggregate_score')}, Total Duration: {total_duration:.2f}s")
        
        return result
    
    def _build_synthesis_prompt(
        self,
        review: Review,
        domain_results: List[Dict[str, Any]],
        artefact_chunks: List[Dict[str, Any]]
    ) -> str:
        """Build prompt for synthesizing domain results"""
        
        # Format domain results
        domains_text = ""
        for result in domain_results:
            domains_text += f"\n=== {result.get('domain_name', result['domain']).upper()} DOMAIN ===\n"
            domains_text += f"Compliance: {result.get('overall_compliance', 'Unknown')}\n"
            domains_text += f"Score: {result.get('compliance_score', 0)}/100\n"
            
            gaps = result.get('gaps', [])
            if gaps:
                domains_text += f"Key Gaps ({len(gaps)}):\n"
                for gap in gaps[:3]:  # Top 3 gaps per domain
                    domains_text += f"  - {gap.get('description', 'N/A')} [{gap.get('severity', 'Unknown')}]\n"
            
            recommendations = result.get('recommendations', [])
            if recommendations:
                domains_text += f"Key Recommendations:\n"
                for rec in recommendations[:2]:  # Top 2 recommendations per domain
                    domains_text += f"  - {rec.get('action', rec) if isinstance(rec, dict) else rec}\n"
        
        # Calculate aggregate metrics
        total_score = sum(r.get('compliance_score', 0) for r in domain_results)
        avg_score = total_score / len(domain_results) if domain_results else 0
        
        critical_gaps = sum(1 for r in domain_results for g in r.get('gaps', []) if g.get('severity') == 'Critical')
        high_gaps = sum(1 for r in domain_results for g in r.get('gaps', []) if g.get('severity') == 'High')
        
        prompt = f"""You are the Chief Architecture Review Board member conducting the final review for:

Solution Name: {review.solution_name}
Scope: {', '.join(review.scope_tags) if review.scope_tags else 'Not specified'}

=== DOMAIN EVALUATION SUMMARY ===
{domains_text}

=== AGGREGATE METRICS ===
Average Compliance Score: {avg_score:.1f}/100
Total Critical Issues: {critical_gaps}
Total High Priority Issues: {high_gaps}
Domains Evaluated: {len(domain_results)}

=== FINAL REVIEW TASK ===
Based on all domain evaluations:

1. Make a final ARB decision: APPROVE, APPROVE_WITH_CONDITIONS, DEFER, or REJECT
2. Consider critical blockers (security, compliance, major architectural gaps)
3. Evaluate overall solution readiness
4. Provide clear rationale for your decision
5. Define specific conditions if approval is conditional
6. Set timeline for remediation if deferred/rejected

=== RESPONSE FORMAT ===
{{
    "decision": "APPROVE|APPROVE_WITH_CONDITIONS|DEFER|REJECT",
    "aggregate_score": {int(avg_score)},
    "rationale": "Detailed explanation of the decision",
    "critical_blockers": ["List of critical issues preventing approval"],
    "conditions": [
        {{
            "condition": "Specific condition to meet",
            "timeline": "Timeline for meeting condition",
            "owner": "Role responsible"
        }}
    ],
    "next_review_date": "YYYY-MM-DD for deferred cases",
    "strengths": ["Overall solution strengths"],
    "major_concerns": ["Cross-domain concerns"],
    "recommendations": ["Strategic recommendations for the team"]
}}

Decision Guidelines:
- APPROVE: No critical issues, score >= 80, all domains compliant
- APPROVE_WITH_CONDITIONS: Minor issues, score >= 70, fixable conditions
- DEFER: Significant issues requiring more work, score >= 50
- REJECT: Critical blockers, score < 50, fundamental architectural problems"""

        return prompt
