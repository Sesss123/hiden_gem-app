import logging
from typing import Dict, Any
from mas.state import AgentState
from services.weather_service import weather_service
from services.telemetry_service import telemetry_service

logger = logging.getLogger("AuditorAgent")

class AuditorAgent:
    async def run(self, state: AgentState) -> Dict[str, Any]:
        """
        Analyzes weather and safety based on location and real-time data.
        """
        district = state.get("district", "Sri Lanka")
        logger.info(f"🛡️ [AuditorAgent] Auditing safety and weather for {district}")
        
        await telemetry_service.update_agent_status(
            "Auditor", "Weather/Safety Check", f"Fetching meteorological data for {district}..."
        )
        
        weather = await weather_service.get_weather_for_district(district)
        
        # Determine safety level (simplified logic, can be enhanced with News search)
        condition = weather.get("condition", "").lower()
        temp = weather.get("temp", 28)
        
        safety_level = "Safe"
        safety_note = "Regular travel conditions."
        
        if "storm" in condition or "rain" in condition:
            safety_level = "Exercise Caution"
            safety_note = f"Current weather indicates {condition}. Surfaces may be slippery. Check local advisories."
        
        if temp > 35:
            safety_note += " Extreme heat alert. Stay hydrated and avoid peak sun hours."

        log_entry = {
            "agent": "Auditor",
            "action": "Safety & Weather Audit",
            "reasoning": f"Weather API reported {weather['description']} with {weather['humidity']}% humidity. Monsoon advice: {weather['monsoon_advice']}. Safety flagged as {safety_level}."
        }
        
        await telemetry_service.update_agent_status(
            "Auditor", "Safety Compliance", log_entry["reasoning"]
        )

        return {
            "weather_data": {
                "current": weather,
                "safety_level": safety_level,
                "safety_note": safety_note
            },
            "reasoning_logs": [log_entry],
            "history": ["audit_complete"]
        }

auditor = AuditorAgent()
