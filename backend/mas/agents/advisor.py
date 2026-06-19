import logging
from typing import Dict, Any
from mas.state import AgentState
from services.telemetry_service import telemetry_service

logger = logging.getLogger("AdvisorAgent")

class AdvisorAgent:
    async def run(self, state: AgentState) -> Dict[str, Any]:
        """
        Personalizes recommendations Based on user profile or context.
        Currently uses metadata to tailor the experience.
        """
        res = state["final_result"]
        category = res.get("category", "").lower()
        
        await telemetry_service.update_agent_status(
            "Advisor", "Recommendation Analysis", f"Tailoring trip for {category} interests..."
        )
        personal_note = ""
        if "waterfall" in category:
            personal_note = "As you enjoy nature, this location is perfect for your interest in landscape photography."
        elif "temple" in category or "historical" in category:
            personal_note = "Given your interest in Sri Lankan heritage, this site's unique inscriptions will be fascinating."
        
        res["personalization"] = {
            "advisor_note": personal_note,
            "target_audience": "Nature Lovers" if "nature" in category else "Culture Seekers"
        }

        log_entry = {
            "agent": "Advisor",
            "action": "Personalization Tuning",
            "reasoning": f"Analyzed destination category ({category}) and applied profile-based tailoring. Added specific recommendations for {res['personalization']['target_audience']}."
        }
        
        await telemetry_service.update_agent_status(
            "Advisor", "Personalization Applied", log_entry["reasoning"]
        )

        return {
            "final_result": res,
            "reasoning_logs": [log_entry],
            "history": ["personalization_complete"]
        }

advisor = AdvisorAgent()
