from typing import Dict, Any, List
from langchain_openai import ChatOpenAI
from app.core.config import settings
from app.models.arb_submission import Decision

class DecisionAgent:
    def __init__(self):
        self.llm = ChatOpenAI(
            model=settings.OPENAI_MODEL,
            temperature=0.1,
            api_key=settings.OPENAI_API_KEY
        )
    
    async def generate_decision(
        self,
        validation_results: Dict[str, Any],
        nfr_scores: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Generate final decision based on validation and NFR results"""
        
        prompt = self._build_decision_prompt(validation_results, nfr_scores)
        
        response = await self.llm.ainvoke(prompt)
        
        decision = self._parse_decision_response(response.content)
        
        return decision
    
    def _build_decision_prompt(
        self,
        validation_results: Dict[str, Any],
        nfr_scores: Dict[str, Any]
    ) -> str:
        """Build decision generation prompt"""
        
        validation_summary = self._format_validation_summary(validation_results)
        nfr_summary = self._format_nfr_summary(nfr_scores)
        
        prompt = f"""You are an expert Enterprise Architect making ARB (Architecture Review Board) decisions.

Domain Validation Results:
{validation_summary}

NFR Assessment Results:
{nfr_summary}

Decision Taxonomy:
- APPROVE: Meets all standards & NFRs; minor actions tracked
- APPROVE w/ ACTIONS: Conditions & timelines; post-ARB validations required
- DEFER: Gaps identified; return with updates by target date
- REJECT: Misaligned, unsafe or unviable; rework required

Decision Priority Rules:
1. Security NFRs must be GREEN (score 3+)
2. DR/HA must be at least AMBER (score 2+)
3. Overall compliance across all domains should be 70%+
4. Any RED NFR score requires DEFER or REJECT

Your task:
1. Analyze the validation and NFR results
2. Apply the decision taxonomy and priority rules
3. Generate a recommendation with clear rationale
4. Identify any conditions or actions required

Provide your response in the following JSON format:
{{
    "recommendation": "APPROVE|APPROVE_WITH_ACTIONS|DEFER|REJECT",
    "rationale": "Clear rationale for the decision",
    "conditions": ["condition1", "condition2"],
    "target_date": "YYYY-MM-DD" (if DEFER or APPROVE_WITH_ACTIONS),
    "critical_gaps": ["gap1", "gap2"],
    "overall_score": 0-100
}}
"""
        return prompt
    
    def _format_validation_summary(self, validation_results: Dict[str, Any]) -> str:
        """Format validation results summary"""
        summary = []
        for domain, result in validation_results.items():
            summary.append(
                f"{domain.upper()}: {result.get('overall_compliance', 'N/A')} "
                f"({result.get('compliance_score', 0)}%)"
            )
            if result.get('gaps'):
                summary.append(f"  Gaps: {', '.join(result['gaps'][:3])}")
        return "\n".join(summary)
    
    def _format_nfr_summary(self, nfr_scores: Dict[str, Any]) -> str:
        """Format NFR assessment summary"""
        summary = []
        for category, score in nfr_scores.items():
            summary.append(
                f"{category.upper()}: {score.get('rag_status', 'N/A')} "
                f"(Score: {score.get('rag_score', 0)})"
            )
        return "\n".join(summary)
    
    def _parse_decision_response(self, response: str) -> Dict[str, Any]:
        """Parse decision response"""
        # In production, use structured output
        # For demo, return mock response
        return {
            "recommendation": "APPROVE_WITH_ACTIONS",
            "rationale": "Solution meets most EA standards but requires actions for security documentation and DR testing evidence.",
            "conditions": [
                "Complete security documentation within 30 days",
                "Provide DR test evidence within 60 days",
                "Update API documentation with versioning"
            ],
            "target_date": "2024-06-01",
            "critical_gaps": [
                "Missing security architecture documentation",
                "No DR test evidence provided"
            ],
            "overall_score": 78
        }
    
    async def generate_adrs(
        self,
        decision: Dict[str, Any],
        validation_results: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Generate Architecture Decision Records"""
        
        adrs = []
        
        # Generate ADR for each critical gap or condition
        for condition in decision.get('conditions', []):
            adr = {
                "id": f"ADR-{len(adrs) + 1}",
                "title": f"Action Required: {condition}",
                "context": f"Based on ARB review with decision: {decision.get('recommendation')}",
                "decision": "Implement the required action",
                "rationale": decision.get('rationale', ''),
                "consequences": [
                    "Improved compliance with EA standards",
                    "Reduced security and operational risks"
                ],
                "status": "OPEN",
                "owner": "Solution Architect",
                "target_date": decision.get('target_date', ''),
                "created_date": "2024-04-09"
            }
            adrs.append(adr)
        
        return adrs
    
    async def generate_action_register(
        self,
        decision: Dict[str, Any],
        validation_results: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Generate action register from decision and validation results"""
        
        actions = []
        
        # Add actions for each condition
        for i, condition in enumerate(decision.get('conditions', [])):
            action = {
                "id": f"ACT-{i + 1}",
                "description": condition,
                "owner": "Solution Architect",
                "target_date": decision.get('target_date', ''),
                "status": "PENDING",
                "priority": "HIGH" if i < 2 else "MEDIUM",
                "linked_adr": f"ADR-{i + 1}"
            }
            actions.append(action)
        
        return actions
