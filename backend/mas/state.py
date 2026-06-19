from typing import TypedDict, List, Dict, Any, Annotated
import operator

class AgentState(TypedDict):
    """
    Main state for the TripMe MAS.
    Annotated[..., operator.setitem] is not needed for simple dicts, 
    but for lists we might want to append.
    """
    # Core identifying info
    destination_name: str
    district: str
    
    # Accumulated data from agents
    raw_data: Dict[str, Any]      # Data from Researcher
    weather_data: Dict[str, Any]  # Data from Auditor
    verification_results: Dict[str, Any] # Data from Verifier (Consensus)
    personalization: Dict[str, Any] # Data from Advisor
    
    # Pipeline control
    history: Annotated[List[str], operator.add]
    next_node: str
    errors: List[str]
    confidence_score: float
    
    # Reasoning logs for Telemetry
    reasoning_logs: Annotated[List[Dict[str, str]], operator.add]
    
    # Final Structured Result
    final_result: Dict[str, Any]
