from langgraph.graph import StateGraph, END
from typing import TypedDict, List, Dict, Any
from app.agents.domain_agents import DomainValidationAgent
from app.agents.nfr_agent import NFRAssessmentAgent
from app.agents.decision_agent import DecisionAgent

class ARBState(TypedDict):
    submission_id: str
    artefacts: List[Dict[str, Any]]
    domain_sections: Dict[str, Any]
    validation_results: Dict[str, Any]
    nfr_scores: Dict[str, Any]
    decision: Dict[str, Any]
    adrs: List[Dict[str, Any]]
    action_register: List[Dict[str, Any]]

class ARBOrchestrator:
    def __init__(self):
        self.domain_agent = DomainValidationAgent()
        self.nfr_agent = NFRAssessmentAgent()
        self.decision_agent = DecisionAgent()
        self.graph = self._build_graph()
    
    def _build_graph(self) -> StateGraph:
        """Build the LangGraph state machine for ARB review"""
        workflow = StateGraph(ARBState)
        
        # Add nodes
        workflow.add_node("parse_artefacts", self.parse_artefacts)
        workflow.add_node("validate_domains", self.validate_domains)
        workflow.add_node("assess_nfrs", self.assess_nfrs)
        workflow.add_node("generate_decision", self.generate_decision)
        workflow.add_node("generate_adrs", self.generate_adrs)
        
        # Define edges
        workflow.set_entry_point("parse_artefacts")
        workflow.add_edge("parse_artefacts", "validate_domains")
        workflow.add_edge("validate_domains", "assess_nfrs")
        workflow.add_edge("assess_nfrs", "generate_decision")
        workflow.add_edge("generate_decision", "generate_adrs")
        workflow.add_edge("generate_adrs", END)
        
        return workflow.compile()
    
    async def parse_artefacts(self, state: ARBState) -> ARBState:
        """Parse uploaded artefacts and extract structured information"""
        # In production, this would use multi-modal LLM to extract text from diagrams
        # For demo, we'll simulate parsing
        state["domain_sections"] = {
            "application": {},
            "integration": {},
            "data": {},
            "security": {},
            "infrastructure": {},
            "devsecops": {}
        }
        return state
    
    async def validate_domains(self, state: ARBState) -> ARBState:
        """Run domain-specific validation agents"""
        domains = ["application", "integration", "data", "security", "infrastructure", "devsecops"]
        validation_results = {}
        
        for domain in domains:
            # Run domain validation agent
            domain_section = state["domain_sections"].get(domain, {})
            result = await self.domain_agent.validate_domain(
                domain=domain,
                section_data=domain_section,
                standards=standards
            )
            validation_results[domain] = result
        
        state["validation_results"] = validation_results
        return state
    
    async def assess_nfrs(self, state: ARBState) -> ARBState:
        """Assess non-functional requirements"""
        nfr_scores = await self.nfr_agent.assess_nfrs(
            validation_results=state["validation_results"],
            domain_sections=state["domain_sections"]
        )
        state["nfr_scores"] = nfr_scores
        return state
    
    async def generate_decision(self, state: ARBState) -> ARBState:
        """Generate final decision based on validation and NFR results"""
        decision = await self.decision_agent.generate_decision(
            validation_results=state["validation_results"],
            nfr_scores=state["nfr_scores"]
        )
        state["decision"] = decision
        return state
    
    async def generate_adrs(self, state: ARBState) -> ARBState:
        """Generate Architecture Decision Records"""
        adrs = await self.decision_agent.generate_adrs(
            decision=state["decision"],
            validation_results=state["validation_results"]
        )
        
        action_register = await self.decision_agent.generate_action_register(
            decision=state["decision"],
            validation_results=state["validation_results"]
        )
        
        state["adrs"] = adrs
        state["action_register"] = action_register
        return state
    
    async def run_review(self, submission_id: str, artefacts: List[Dict[str, Any]], domain_sections: Dict[str, Any]) -> Dict[str, Any]:
        """Run the complete ARB review pipeline"""
        initial_state: ARBState = {
            "submission_id": submission_id,
            "artefacts": artefacts,
            "domain_sections": domain_sections,
            "validation_results": {},
            "nfr_scores": {},
            "decision": {},
            "adrs": [],
            "action_register": []
        }
        
        final_state = await self.graph.ainvoke(initial_state)
        return final_state

orchestrator = ARBOrchestrator()
