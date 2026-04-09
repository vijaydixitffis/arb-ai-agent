from app.vector_store.chroma_setup import vector_store
from typing import List, Dict, Any

class KnowledgeBaseService:
    def __init__(self):
        self.vector_store = vector_store
    
    def populate_sample_knowledge(self):
        """Populate the knowledge base with sample EA standards"""
        # Application Architecture
        self._populate_application_architecture()
        
        # Integration Architecture
        self._populate_integration_architecture()
        
        # Data Architecture
        self._populate_data_architecture()
        
        # Security Architecture
        self._populate_security_architecture()
        
        # Infrastructure Architecture
        self._populate_infrastructure_architecture()
        
        # DevSecOps
        self._populate_devsecops()
    
    def _populate_application_architecture(self):
        """Populate application architecture standards"""
        documents = [
            "Applications must follow microservices architecture principles with clear service boundaries.",
            "Technology stack must be from approved technology catalogue with no deprecated versions.",
            "Applications must implement circuit breaker pattern for external service calls.",
            "API versioning must follow semantic versioning (v1, v2, etc.) with backward compatibility.",
            "Stateless design preferred for scalability and resilience.",
            "SBOM (Software Bill of Materials) must be generated and maintained for all applications."
        ]
        metadatas = [{"domain": "application", "category": "architecture"} for _ in documents]
        self.vector_store.add_documents("application_architecture", documents, metadatas)
    
    def _populate_integration_architecture(self):
        """Populate integration architecture standards"""
        documents = [
            "All APIs must follow RESTful principles with proper HTTP verbs and status codes.",
            "API documentation must be maintained in OpenAPI/Swagger format.",
            "Event-driven integrations must use standard event schemas with proper versioning.",
            "Integration catalogue must be maintained with all system interfaces documented.",
            "Rate limiting must be implemented for all public APIs.",
            "Idempotency must be ensured for all write operations."
        ]
        metadatas = [{"domain": "integration", "category": "architecture"} for _ in documents]
        self.vector_store.add_documents("integration_architecture", documents, metadatas)
    
    def _populate_data_architecture(self):
        """Populate data architecture standards"""
        documents = [
            "All data must be classified according to data classification policy (Public, Internal, Confidential, Restricted).",
            "Data model documentation must be maintained with entity relationships and constraints.",
            "PII data must be encrypted at rest and in transit.",
            "Data lifecycle management must be implemented with retention policies.",
            "End-of-life (EoL) and End-of-support (EoS) tracking for all data stores.",
            "Data lineage must be traceable from source to consumption."
        ]
        metadatas = [{"domain": "data", "category": "architecture"} for _ in documents]
        self.vector_store.add_documents("data_architecture", documents, metadatas)
    
    def _populate_security_architecture(self):
        """Populate security architecture standards"""
        documents = [
            "Authentication must use OAuth 2.0/OIDC with Azure AD as identity provider.",
            "Authorization must implement RBAC (Role-Based Access Control) with principle of least privilege.",
            "All applications must undergo VAPT (Vulnerability Assessment and Penetration Testing) before production.",
            "TLS 1.3 must be used for all encrypted communications.",
            "Secrets must be stored in Azure Key Vault with managed identities.",
            "Security logging and monitoring must be implemented with SIEM integration."
        ]
        metadatas = [{"domain": "security", "category": "architecture"} for _ in documents]
        self.vector_store.add_documents("security_architecture", documents, metadatas)
    
    def _populate_infrastructure_architecture(self):
        """Populate infrastructure architecture standards"""
        documents = [
            "Infrastructure must be provisioned using Infrastructure as Code (IaC) with Terraform or CloudFormation.",
            "Multi-environment strategy: Development, Testing, Staging, Production.",
            "Platform upgrades must be planned with rollback procedures.",
            "Capacity planning must be done with 12-18 month forecast.",
            "EoL and EoS tracking for all infrastructure components.",
            "Disaster Recovery with defined RPO (Recovery Point Objective) and RTO (Recovery Time Objective)."
        ]
        metadatas = [{"domain": "infrastructure", "category": "architecture"} for _ in documents]
        self.vector_store.add_documents("infrastructure_architecture", documents, metadatas)
    
    def _populate_devsecops(self):
        """Populate DevSecOps standards"""
        documents = [
            "CI/CD pipeline must include automated testing, SAST, DAST, and container scanning.",
            "Code reviews must be mandatory for all pull requests.",
            "Test coverage must be at least 80% for critical business logic.",
            "Deployment strategy must support blue-green or canary deployments.",
            "Defect tracking must be integrated with development workflow.",
            "Quality gates must be defined and enforced in the pipeline."
        ]
        metadatas = [{"domain": "devsecops", "category": "architecture"} for _ in documents]
        self.vector_store.add_documents("devsecops", documents, metadatas)
    
    def query_standards(self, domain: str, query: str, n_results: int = 5) -> List[Dict[str, Any]]:
        """Query standards for a specific domain"""
        collection_name = f"{domain}_architecture"
        if collection_name not in self.vector_store.collections:
            return []
        
        results = self.vector_store.query(collection_name, query, n_results)
        return [
            {
                "text": results["documents"][0][i],
                "metadata": results["metadatas"][0][i] if results["metadatas"] else {},
                "distance": results["distances"][0][i] if results["distances"] else 0
            }
            for i in range(len(results["documents"][0]))
        ]

# Global instance
knowledge_base_service = KnowledgeBaseService()
