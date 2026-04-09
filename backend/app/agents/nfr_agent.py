from typing import Dict, Any, List
from langchain_openai import ChatOpenAI
from app.core.config import settings

class NFRAssessmentAgent:
    def __init__(self):
        self.llm = ChatOpenAI(
            model=settings.OPENAI_MODEL,
            temperature=0.1,
            api_key=settings.OPENAI_API_KEY
        )
    
    async def assess_nfrs(
        self,
        validation_results: Dict[str, Any],
        domain_sections: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Assess non-functional requirements and generate RAG scores"""
        
        nfr_categories = [
            "scalability_performance",
            "ha_resilience_dr",
            "security_nfrs",
            "engineering_quality"
        ]
        
        nfr_scores = {}
        
        for category in nfr_categories:
            score = await self._assess_category(
                category,
                validation_results,
                domain_sections
            )
            nfr_scores[category] = score
        
        return nfr_scores
    
    async def _assess_category(
        self,
        category: str,
        validation_results: Dict[str, Any],
        domain_sections: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Assess a specific NFR category"""
        
        # Build prompt based on category
        prompt = self._build_nfr_prompt(category, validation_results, domain_sections)
        
        # Get LLM response
        response = await self.llm.ainvoke(prompt)
        
        # Parse response
        score_result = self._parse_nfr_response(response.content, category)
        
        return score_result
    
    def _build_nfr_prompt(
        self,
        category: str,
        validation_results: Dict[str, Any],
        domain_sections: Dict[str, Any]
    ) -> str:
        """Build NFR assessment prompt"""
        
        category_descriptions = {
            "scalability_performance": "Scalability and Performance",
            "ha_resilience_dr": "High Availability, Resilience and Disaster Recovery",
            "security_nfrs": "Security Non-Functional Requirements",
            "engineering_quality": "Engineering Quality"
        }
        
        prompt = f"""You are an expert in assessing {category_descriptions.get(category, category)}.

Domain Validation Results:
{self._format_validation_results(validation_results)}

Your task:
1. Assess the {category_descriptions.get(category, category)} based on the validation results
2. Provide a RAG (Red/Amber/Green) score: 1=Red, 2=Amber, 3=Green, 4=Green+, 5=Green++
3. Identify specific gaps or concerns
4. Provide recommendations for improvement

Provide your response in the following JSON format:
{{
    "category": "{category}",
    "rag_score": 1-5,
    "rag_status": "RED|AMBER|GREEN",
    "gaps": ["gap1", "gap2"],
    "recommendations": ["recommendation1", "recommendation2"],
    "evidence_required": ["evidence1"]
}}
"""
        return prompt
    
    def _format_validation_results(self, validation_results: Dict[str, Any]) -> str:
        """Format validation results for prompt"""
        formatted = []
        for domain, result in validation_results.items():
            formatted.append(f"{domain}: {result.get('overall_compliance', 'N/A')} ({result.get('compliance_score', 0)}%)")
        return "\n".join(formatted)
    
    def _parse_nfr_response(self, response: str, category: str) -> Dict[str, Any]:
        """Parse NFR assessment response"""
        # In production, use structured output
        # For demo, return mock response
        return {
            "category": category,
            "rag_score": 3,
            "rag_status": "GREEN",
            "gaps": [],
            "recommendations": [
                "Monitor performance metrics continuously",
                "Implement automated scaling policies"
            ],
            "evidence_required": []
        }
