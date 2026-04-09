from typing import Dict, Any, List
from langchain_openai import ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from app.core.config import settings

class DomainValidationAgent:
    def __init__(self):
        self.llm = ChatOpenAI(
            model=settings.OPENAI_MODEL,
            temperature=0.1,
            api_key=settings.OPENAI_API_KEY
        )
    
    async def validate_domain(
        self,
        domain: str,
        section_data: Dict[str, Any],
        standards: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Validate a specific domain against EA standards"""
        
        # Extract checklist items from section data
        checklist_items = section_data.get("checklist_items", [])
        
        # Build prompt with standards and checklist
        prompt = self._build_validation_prompt(domain, standards, checklist_items)
        
        # Get LLM response
        response = await self.llm.ainvoke(prompt)
        
        # Parse response (in production, use structured output)
        validation_result = self._parse_validation_response(response.content, domain)
        
        return validation_result
    
    def _build_validation_prompt(
        self,
        domain: str,
        standards: List[Dict[str, Any]],
        checklist_items: List[Dict[str, Any]]
    ) -> str:
        """Build validation prompt for LLM"""
        standards_text = "\n".join([
            f"- {std['text']}" for std in standards
        ])
        
        checklist_text = "\n".join([
            f"- {item.get('question', 'N/A')}: {item.get('answer', 'N/A')} (Evidence: {item.get('evidence_notes', 'None')})"
            for item in checklist_items
        ])
        
        prompt = f"""You are an expert Enterprise Architecture validator for {domain} domain.

EA Standards for {domain}:
{standards_text}

Checklist Answers Provided:
{checklist_text}

Your task:
1. Review each checklist item against the EA standards
2. Identify gaps or non-compliant areas
3. Provide specific recommendations for improvement
4. Rate the overall compliance as: COMPLIANT, PARTIALLY_COMPLIANT, or NON_COMPLIANT

Provide your response in the following JSON format:
{{
    "domain": "{domain}",
    "overall_compliance": "COMPLIANT|PARTIALLY_COMPLIANT|NON_COMPLIANT",
    "compliance_score": 0-100,
    "gaps": ["gap1", "gap2"],
    "recommendations": ["recommendation1", "recommendation2"],
    "evidence_required": ["evidence1", "evidence2"]
}}
"""
        return prompt
    
    def _parse_validation_response(self, response: str, domain: str) -> Dict[str, Any]:
        """Parse LLM response into structured result"""
        # In production, use structured output from LangChain
        # For demo, return a mock response
        return {
            "domain": domain,
            "overall_compliance": "PARTIALLY_COMPLIANT",
            "compliance_score": 75,
            "gaps": [
                "Missing SBOM documentation",
                "API versioning not clearly defined"
            ],
            "recommendations": [
                "Generate and maintain SBOM for all components",
                "Implement semantic versioning for all APIs"
            ],
            "evidence_required": [
                "SBOM file in CycloneDX format",
                "API documentation with version information"
            ]
        }
