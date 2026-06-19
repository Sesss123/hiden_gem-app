import httpx
import os
import logging
from typing import Dict, Any, Optional

logger = logging.getLogger("WeatherService")

class WeatherService:
    def __init__(self):
        self.api_key = os.getenv("OPENWEATHERMAP_API_KEY")
        self.base_url = "https://api.openweathermap.org/data/2.5/weather"

    async def get_weather_for_district(self, district: str) -> Dict[str, Any]:
        """
        Fetch current weather and seasonal advice for a specific Sri Lankan district.
        """
        if not self.api_key:
            logger.warning(f"⚠️ No OpenWeatherMap API key found. Providing smart simulation for {district}.")
            return self._simulate_weather(district)

        try:
            async with httpx.AsyncClient() as client:
                params = {
                    "q": f"{district},LK",
                    "appid": self.api_key,
                    "units": "metric"
                }
                response = await client.get(self.base_url, params=params)
                if response.status_code == 200:
                    data = response.json()
                    return {
                        "temp": data["main"]["temp"],
                        "condition": data["weather"][0]["main"],
                        "description": data["weather"][0]["description"],
                        "humidity": data["main"]["humidity"],
                        "is_simulated": False,
                        "monsoon_advice": self._get_monsoon_advice(district)
                    }
                else:
                    return self._simulate_weather(district)
        except Exception as e:
            logger.error(f"❌ Weather API Error: {e}")
            return self._simulate_weather(district)

    def _get_monsoon_advice(self, district: str) -> str:
        """Determines monsoon sensitivity based on SL district geography."""
        west_south = ["Colombo", "Gampaha", "Kalutara", "Galle", "Matara", "Ratnapura", "Kegalle", "Nuwara Eliya"]
        east_north = ["Jaffna", "Trincomalee", "Batticaloa", "Ampara", "Polonnaruwa", "Anuradhapura"]
        
        from datetime import datetime
        month = datetime.now().month
        
        # Southwest Monsoon (May - Sept)
        if 5 <= month <= 9:
            if district in west_south:
                return "Active Southwest Monsoon. High rain sensitivity. Avoid waterfalls/hiking in the afternoon."
            return "Inter-monsoon period. Generally dry in this region."
            
        # Northeast Monsoon (Dec - Feb)
        if month in [12, 1, 2]:
            if district in east_north:
                return "Active Northeast Monsoon. Coastal areas may be rough. Frequent showers expected."
            return "Peak tourism season. Dry and sunny weather in West/South coasts."
            
        return "Inter-monsoon period. Frequent lightning and evening thunderstorms possible."

    def _simulate_weather(self, district: str) -> Dict[str, Any]:
        """Simulation fallback if API key is missing."""
        return {
            "temp": 28.5,
            "condition": "Partly Cloudy",
            "description": "Scattered clouds with tropical humidity",
            "humidity": 75,
            "is_simulated": True,
            "monsoon_advice": self._get_monsoon_advice(district)
        }

weather_service = WeatherService()
