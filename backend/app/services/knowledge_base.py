from app.vector_store.chroma_setup import vector_store
from app.utils.markdown_parser import markdown_parser
from typing import List, Dict, Any
from pathlib import Path

class KnowledgeBaseService:
    def __init__(self):
        self.vector_store = vector_store
        self.knowledge_base_path = Path(__file__).parent.parent.parent.parent / "knowledge-base"
    
    def populate_from_markdown(self):
        """Populate the knowledge base from markdown files"""
        # Load EA principles into architecture_principles collection
        self._load_principles_from_markdown("ea-principles.md", "architecture_principles")
        
        # Load Integration principles into architecture_principles collection
        self._load_principles_from_markdown("integration-principles.md", "architecture_principles")
    
    def _load_principles_from_markdown(self, filename: str, collection_name: str):
        """Load principles from a markdown file into a collection"""
        file_path = self.knowledge_base_path / filename
        
        if not file_path.exists():
            print(f"Warning: {filename} not found at {file_path}")
            return
        
        # Parse the markdown file
        principles = markdown_parser.parse_file(str(file_path))
        
        # Extract ARB weights
        weights = markdown_parser.extract_arb_weight(str(file_path))
        
        # Create documents and metadata for each principle
        documents = []
        metadatas = []
        ids = []
        
        for principle in principles:
            # Create multiple chunks per principle for better retrieval
            # Chunk 1: Full principle text
            full_text = f"Principle {principle['id']}: {principle['title']}\n\n"
            full_text += f"Statement: {principle['statement']}\n\n"
            full_text += f"Rationale: {principle['rationale']}\n\n"
            full_text += f"Implications: {'; '.join(principle['implications'])}\n\n"
            full_text += f"Items to Verify: {'; '.join(principle['items_to_verify'])}"
            
            documents.append(full_text)
            metadatas.append({
                "principle_id": principle['id'],
                "title": principle['title'],
                "category": principle['category'],
                "arb_weight": weights.get(principle['id'], "Medium"),
                "section": "full"
            })
            ids.append(f"{principle['id']}_full")
            
            # Chunk 2: Statement + Rationale
            statement_rationale = f"Principle {principle['id']}: {principle['title']}\n\n"
            statement_rationale += f"Statement: {principle['statement']}\n\n"
            statement_rationale += f"Rationale: {principle['rationale']}"
            
            documents.append(statement_rationale)
            metadatas.append({
                "principle_id": principle['id'],
                "title": principle['title'],
                "category": principle['category'],
                "arb_weight": weights.get(principle['id'], "Medium"),
                "section": "statement_rationale"
            })
            ids.append(f"{principle['id']}_sr")
            
            # Chunk 3: Implications
            implications_text = f"Principle {principle['id']}: {principle['title']} - Implications\n\n"
            implications_text += "\n".join([f"- {imp}" for imp in principle['implications']])
            
            documents.append(implications_text)
            metadatas.append({
                "principle_id": principle['id'],
                "title": principle['title'],
                "category": principle['category'],
                "arb_weight": weights.get(principle['id'], "Medium"),
                "section": "implications"
            })
            ids.append(f"{principle['id']}_imp")
            
            # Chunk 4: Items to Verify
            verify_text = f"Principle {principle['id']}: {principle['title']} - Verification Checklist\n\n"
            verify_text += "\n".join([f"- {item}" for item in principle['items_to_verify']])
            
            documents.append(verify_text)
            metadatas.append({
                "principle_id": principle['id'],
                "title": principle['title'],
                "category": principle['category'],
                "arb_weight": weights.get(principle['id'], "Medium"),
                "section": "verify"
            })
            ids.append(f"{principle['id']}_verify")
        
        # Add to vector store
        if documents:
            self.vector_store.add_documents(collection_name, documents, metadatas, ids)
            print(f"Loaded {len(principles)} principles from {filename} into {collection_name} ({len(documents)} chunks)")
    
    def populate_sample_knowledge(self):
        """Populate the knowledge base with sample EA standards (legacy, use populate_from_markdown instead)"""
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
    
    def query_principles(self, collection_name: str, query: str, n_results: int = 5, 
                         category: str = None, arb_weight: str = None) -> List[Dict[str, Any]]:
        """Query principles from a collection with optional filters"""
        if collection_name not in self.vector_store.collections:
            return []
        
        # Build where clause for filtering
        where = {}
        if category:
            where["category"] = category
        if arb_weight:
            where["arb_weight"] = arb_weight
        
        results = self.vector_store.query(collection_name, query, n_results, where)
        
        if not results or "documents" not in results or not results["documents"]:
            return []
        
        return [
            {
                "text": results["documents"][0][i],
                "metadata": results["metadatas"][0][i] if results["metadatas"] else {},
                "distance": results["distances"][0][i] if results["distances"] else 0
            }
            for i in range(len(results["documents"][0]))
        ]
    
    def query_standards(self, domain: str, query: str, n_results: int = 5) -> List[Dict[str, Any]]:
        """Query standards for a specific domain (legacy method)"""
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
    
    def get_principle_by_id(self, collection_name: str, principle_id: str) -> Dict[str, Any]:
        """Get a specific principle by ID"""
        if collection_name not in self.vector_store.collections:
            return None
        
        # Query with where clause for principle_id
        results = self.vector_store.query(
            collection_name, 
            f"Principle {principle_id}", 
            n_results=10,
            where={"principle_id": principle_id}
        )
        
        if not results or "documents" not in results or not results["documents"]:
            return None
        
        # Return the full principle (the chunk with section="full")
        for i in range(len(results["documents"][0])):
            metadata = results["metadatas"][0][i] if results["metadatas"] else {}
            if metadata.get("section") == "full":
                return {
                    "text": results["documents"][0][i],
                    "metadata": metadata,
                    "distance": results["distances"][0][i] if results["distances"] else 0
                }
        
        # If no full chunk found, return the first result
        return {
            "text": results["documents"][0][0],
            "metadata": results["metadatas"][0][0] if results["metadatas"] else {},
            "distance": results["distances"][0][0] if results["distances"] else 0
        }

# Global instance
knowledge_base_service = KnowledgeBaseService()
