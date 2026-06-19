import logging
from typing import Dict, Any, Literal
from langgraph.graph import StateGraph, END
from mas.state import AgentState
from mas.agents.researcher import researcher
from mas.agents.auditor import auditor
from mas.agents.verifier import verifier
from mas.agents.advisor import advisor

logger = logging.getLogger("Supervisor")

class Supervisor:
    def __init__(self):
        self.workflow = StateGraph(AgentState)
        self._setup_graph()

    def _setup_graph(self):
        """
        Defines the DAG for the Multi-Agent System.
        """
        # Define Nodes
        self.workflow.add_node("researcher", researcher.run)
        self.workflow.add_node("auditor", auditor.run)
        self.workflow.add_node("verifier", verifier.run)
        self.workflow.add_node("advisor", advisor.run)

        # Build Flow
        self.workflow.set_entry_point("researcher")
        
        self.workflow.add_edge("researcher", "auditor")
        self.workflow.add_edge("auditor", "verifier")
        
        # Verification Logic (Cycle or Proceed)
        self.workflow.add_conditional_edges(
            "verifier",
            self._routing_logic,
            {
                "continue": "advisor",
                "re_research": "researcher",
                "fail": END
            }
        )
        
        self.workflow.add_edge("advisor", END)
        
        # Compile
        self.app = self.workflow.compile()

    def _routing_logic(self, state: AgentState) -> Literal["continue", "re_research", "fail"]:
        """
        Decision engine for the Verifier node.
        """
        score = state.get("confidence_score", 0)
        history = state.get("history", [])
        
        if "verification_failed" in history:
            return "fail"
            
        if score >= 60:
            return "continue"
        
        # If low score and we haven't retried yet
        if "re_research_triggered" not in history:
            logger.info("⚠️ [Supervisor] Low consensus. Triggering re-research.")
            # We would modify state here in a real run, but return edge for now
            return "re_research"
            
        return "continue" # Proceed anyway if retry failed

    async def execute(self, destination: str, district: str) -> Dict[str, Any]:
        """
        Run the MAS for a given destination.
        """
        initial_state = {
            "destination_name": destination,
            "district": district,
            "raw_data": {},
            "weather_data": {},
            "verification_results": {},
            "personalization": {},
            "history": [],
            "errors": [],
            "confidence_score": 0,
            "reasoning_logs": [],
            "final_result": {}
        }
        
        result = await self.app.ainvoke(initial_state)
        return result

supervisor = Supervisor()
