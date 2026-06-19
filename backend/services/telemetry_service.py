import httpx
import os
import logging
from typing import Dict, Any

logger = logging.getLogger("TelemetryService")

class TelemetryService:
    def __init__(self):
        self.base_url = "http://localhost:8000/api/pipeline/update-status"
        self.internal_key = os.getenv("INTERNAL_API_KEY")

    async def update_agent_status(self, agent_name: str, action: str, reasoning: str, score: float = None):
        """
        Sends live agent activity to the Genesis Admin Dashboard.
        """
        try:
            async with httpx.AsyncClient() as client:
                data = {
                    "status": "running",
                    "current_step": f"MAS: {agent_name} - {action}",
                    "score": score,
                    "worker_info": {
                        "url": f"mas://{agent_name.lower()}",
                        "step": reasoning,
                        "cache_hit": False
                    }
                }
                headers = {"X-Admin-Internal-Key": self.internal_key}
                await client.post(self.base_url, json=data, headers=headers)
        except Exception as e:
            logger.error(f"Failed to send telemetry: {e}")

telemetry_service = TelemetryService()
