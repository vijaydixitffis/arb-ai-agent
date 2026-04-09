import chromadb
from chromadb.config import Settings
from app.core.config import settings
from typing import List, Dict, Any

class ChromaVectorStore:
    def __init__(self):
        self.client = chromadb.PersistentClient(
            path=settings.CHROMA_PERSIST_DIRECTORY,
            settings=Settings(
                anonymized_telemetry=False,
                allow_reset=True
            )
        )
        self.collections = {}
        self._initialize_collections()
    
    def _initialize_collections(self):
        """Initialize collections for each domain"""
        domain_collections = [
            "application_architecture",
            "integration_architecture",
            "data_architecture",
            "security_architecture",
            "infrastructure_architecture",
            "devsecops",
            "nfr_criteria",
            "architecture_principles",
            "approved_patterns",
            "standards_policies",
            "adr_repository"
        ]
        
        for collection_name in domain_collections:
            try:
                collection = self.client.get_or_create_collection(
                    name=collection_name,
                    metadata={
                        "hnsw:space": "cosine",
                        "description": f"Collection for {collection_name}"
                    }
                )
                self.collections[collection_name] = collection
            except Exception as e:
                print(f"Error creating collection {collection_name}: {e}")
    
    def add_documents(
        self,
        collection_name: str,
        documents: List[str],
        metadatas: List[Dict[str, Any]] = None,
        ids: List[str] = None
    ):
        """Add documents to a collection"""
        if collection_name not in self.collections:
            raise ValueError(f"Collection {collection_name} not found")
        
        if ids is None:
            ids = [f"{collection_name}_{i}" for i in range(len(documents))]
        
        self.collections[collection_name].add(
            documents=documents,
            metadatas=metadatas,
            ids=ids
        )
    
    def query(
        self,
        collection_name: str,
        query_text: str,
        n_results: int = 5,
        where: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """Query a collection"""
        if collection_name not in self.collections:
            raise ValueError(f"Collection {collection_name} not found")
        
        results = self.collections[collection_name].query(
            query_texts=[query_text],
            n_results=n_results,
            where=where
        )
        return results
    
    def delete_collection(self, collection_name: str):
        """Delete a collection"""
        if collection_name in self.collections:
            self.client.delete_collection(name=collection_name)
            del self.collections[collection_name]

# Global instance
vector_store = ChromaVectorStore()
