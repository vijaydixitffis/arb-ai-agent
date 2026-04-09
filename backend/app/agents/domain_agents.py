from typing import Dict, Any, List
from langchain_openai import ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from app.core.config import settings
from app.services.knowledge_base import knowledge_base_service

class DomainValidationAgent:
    def __init__(self):
        self.llm = ChatOpenAI(
            model=settings.OPENAI_MODEL,
            temperature=0.1,
            api_key=settings.OPENAI_API_KEY
        )
        
        # All principles now go to architecture_principles collection
        # Map domain names to categories for filtering
        self.domain_to_categories = {
            "application": ["Application", "Software", "API-Based"],
            "integration": ["API-Based", "File-Based", "Message-Based"],
            "data": ["Data"],
            "security": ["Security"],
            "infrastructure": ["Infrastructure", "Operations"],
            "devsecops": ["Governance", "Operations", "Software"]
        }
        
        # Map domain names to standard domains for filtering
        self.domain_to_standards = {
            "application": "Application",
            "integration": "Application",
            "data": "Data",
            "security": "Technology",
            "infrastructure": "Technology",
            "devsecops": "Technology"
        }
    
    async def validate_domain(
        self,
        domain: str,
        section_data: Dict[str, Any],
        standards: List[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Validate a specific domain against EA standards"""
        
        # Extract checklist items from section data
        checklist_items = section_data.get("checklist_items", [])
        
        # Retrieve principles from knowledge base
        principles = self._retrieve_principles(domain, section_data)
        
        # Retrieve standards from knowledge base
        standards = self._retrieve_standards(domain, section_data)
        
        # Build prompt with principles, standards, and checklist
        prompt = self._build_validation_prompt(domain, principles, standards, checklist_items, section_data)
        
        # Get LLM response
        response = await self.llm.ainvoke(prompt)
        
        # Parse response (in production, use structured output)
        validation_result = self._parse_validation_response(response.content, domain)
        
        return validation_result
    
    def _retrieve_principles(self, domain: str, section_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Retrieve relevant principles from knowledge base"""
        # All principles now in architecture_principles collection
        collection_name = "architecture_principles"
        
        # Get categories for this domain
        categories = self.domain_to_categories.get(domain, ["General"])
        
        # Build query based on domain and section data
        query = f"{domain} architecture principles"
        
        # Add section-specific terms to query
        if "integration" in domain.lower():
            query += " API gateway mediation file transfer message broker"
        elif "security" in domain.lower():
            query += " authentication authorization encryption security"
        elif "data" in domain.lower():
            query += " data classification lineage governance"
        elif "infrastructure" in domain.lower():
            query += " infrastructure scalability reliability cloud"
        
        # Query knowledge base for each category and combine results
        all_principles = []
        for category in categories:
            principles = knowledge_base_service.query_principles(
                collection_name=collection_name,
                query=query,
                n_results=5,  # Get top 5 per category
                category=category
            )
            all_principles.extend(principles)
        
        # Also include General principles for all domains
        general_principles = knowledge_base_service.query_principles(
            collection_name=collection_name,
            query=f"General architecture principles",
            n_results=5,
            category="General"
        )
        all_principles.extend(general_principles)
        
        # Deduplicate by principle_id
        seen_ids = set()
        unique_principles = []
        for principle in all_principles:
            principle_id = principle.get("metadata", {}).get("principle_id")
            if principle_id and principle_id not in seen_ids:
                seen_ids.add(principle_id)
                unique_principles.append(principle)
        
        return unique_principles
    
    def _retrieve_standards(self, domain: str, section_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Retrieve relevant standards from knowledge base"""
        # Get standard domain for this domain
        standard_domain = self.domain_to_standards.get(domain, None)
        
        if not standard_domain:
            return []
        
        # Build query based on domain and section data
        query = f"{domain} architecture standards compliance"
        
        # Add section-specific terms to query
        if "integration" in domain.lower():
            query += " API gateway mediation file transfer message broker"
        elif "security" in domain.lower():
            query += " authentication authorization encryption security"
        elif "data" in domain.lower():
            query += " data classification lineage governance"
        elif "infrastructure" in domain.lower():
            query += " infrastructure scalability reliability cloud"
        
        # Query knowledge base for standards
        standards = knowledge_base_service.query_standards(
            domain=standard_domain,
            query=query,
            n_results=5  # Get top 5 standards
        )
        
        # Deduplicate by standard_id
        seen_ids = set()
        unique_standards = []
        for standard in standards:
            standard_id = standard.get("metadata", {}).get("standard_id")
            if standard_id and standard_id not in seen_ids:
                seen_ids.add(standard_id)
                unique_standards.append(standard)
        
        return unique_standards
    
    def _build_validation_prompt(
        self,
        domain: str,
        principles: List[Dict[str, Any]],
        standards: List[Dict[str, Any]],
        checklist_items: List[Dict[str, Any]],
        section_data: Dict[str, Any]
    ) -> str:
        """Build validation prompt for LLM"""
        
        # Format principles for prompt
        principles_text = ""
        for i, principle in enumerate(principles[:10], 1):  # Limit to top 10 principles
            metadata = principle.get("metadata", {})
            principle_id = metadata.get("principle_id", "Unknown")
            title = metadata.get("title", "Unknown")
            arb_weight = metadata.get("arb_weight", "Medium")
            text = principle.get("text", "")
            
            principles_text += f"\n{i}. Principle {principle_id}: {title} (ARB Weight: {arb_weight})\n"
            principles_text += f"   {text}\n"
        
        # Format standards for prompt
        standards_text = ""
        for i, standard in enumerate(standards[:10], 1):  # Limit to top 10 standards
            metadata = standard.get("metadata", {})
            standard_id = metadata.get("standard_id", "Unknown")
            title = metadata.get("title", "Unknown")
            domain_std = metadata.get("domain", "Unknown")
            text = standard.get("text", "")
            
            standards_text += f"\n{i}. Standard {standard_id}: {title} (Domain: {domain_std})\n"
            standards_text += f"   {text}\n"
        
        # Format checklist items
        checklist_text = ""
        for item in checklist_items:
            question = item.get('question', 'N/A')
            answer = item.get('answer', 'N/A')
            evidence = item.get('evidence_notes', 'None')
            checklist_text += f"- {question}: {answer} (Evidence: {evidence})\n"
        
        # Format integration catalogue if present
        integration_info = ""
        if "integration_catalogue" in section_data:
            integration_info = "\nIntegration Catalogue:\n"
            for item in section_data["integration_catalogue"]:
                integration_info += f"- Provider: {item.get('provider', 'N/A')}, Consumer: {item.get('consumer', 'N/A')}, Pattern: {item.get('pattern', 'N/A')}\n"
        
        prompt = f"""You are an expert Enterprise Architecture validator for the {domain} domain.

Architecture Principles for {domain}:
{principles_text}

Architecture Standards for {domain}:
{standards_text}

Checklist Answers Provided:
{checklist_text}
{integration_info}

Your task:
1. Review each checklist item against the architecture principles and standards
2. Identify gaps or non-compliant areas
3. For each gap, reference the specific principle ID and/or standard ID that is violated
4. Provide specific recommendations for improvement
5. Rate the overall compliance as: COMPLIANT, PARTIALLY_COMPLIANT, or NON_COMPLIANT
6. Consider the ARB weight of violated principles (Critical violations should result in NON_COMPLIANT)
7. Standards are prescriptive requirements - non-compliance with standards should be treated as high severity

Provide your response in the following JSON format:
{{
    "domain": "{domain}",
    "overall_compliance": "COMPLIANT|PARTIALLY_COMPLIANT|NON_COMPLIANT",
    "compliance_score": 0-100,
    "gaps": [
        {{
            "principle_id": "INT-01",
            "standard_id": "A-STD-01",
            "description": "Gap description",
            "severity": "Critical|High|Medium|Low"
        }}
    ],
    "recommendations": ["recommendation1", "recommendation2"],
    "evidence_required": ["evidence1", "evidence2"],
    "violated_principles": ["INT-01", "INT-05"],
    "violated_standards": ["A-STD-01", "A-STD-02"]
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
                {
                    "principle_id": "INT-01",
                    "description": "Integration not routed through API Gateway",
                    "severity": "Critical"
                },
                {
                    "principle_id": "INT-03",
                    "description": "Integration catalogue incomplete",
                    "severity": "High"
                }
            ],
            "recommendations": [
                "Route all integrations through enterprise API Gateway",
                "Complete integration catalogue with all system interfaces"
            ],
            "evidence_required": [
                "API Gateway configuration",
                "Updated integration catalogue"
            ],
            "violated_principles": ["INT-01", "INT-03"]
        }
