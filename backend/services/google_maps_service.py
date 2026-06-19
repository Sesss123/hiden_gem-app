import httpx
import os
import logging
from core import config

logger = logging.getLogger("GoogleMapsService")

class GoogleMapsService:
    def __init__(self):
        self.api_key = os.getenv("GOOGLE_API_KEY_1") or os.getenv("GOOGLE_API_KEY")
        self.base_url = "https://maps.googleapis.com/maps/api/place"

    async def find_place_details(self, place_name: str, location_hint: str = "Sri Lanka"):
        """
        Enrich a place using Google Places API.
        1. Search for Place ID using Text Search
        2. Get Place Details using Place ID
        """
        if not self.api_key:
            logger.warning("⚠️ No Google Maps API key found. Skipping enrichment.")
            return None

        try:
            async with httpx.AsyncClient() as client:
                # Step 1: Find Place ID
                search_query = f"{place_name}, {location_hint}"
                search_res = await client.get(
                    f"{self.base_url}/findplacefromtext/json",
                    params={
                        "input": search_query,
                        "inputtype": "textquery",
                        "fields": "place_id,name,formatted_address,geometry",
                        "key": self.api_key
                    }
                )
                
                search_data = search_res.json()
                if search_data.get("status") != "OK" or not search_data.get("candidates"):
                    logger.warning(f"🔍 No Google Maps candidate for: {place_name}")
                    return None

                candidate = search_data["candidates"][0]
                place_id = candidate["place_id"]

                # Step 2: Get Deep Details
                details_res = await client.get(
                    f"{self.base_url}/details/json",
                    params={
                        "place_id": place_id,
                        "fields": "rating,user_ratings_total,opening_hours,formatted_phone_number,website,url",
                        "key": self.api_key
                    }
                )
                
                details_data = details_res.json().get("result", {})

                return {
                    "google_place_id": place_id,
                    "google_rating": details_data.get("rating"),
                    "google_user_ratings_total": details_data.get("user_ratings_total"),
                    "google_address": candidate.get("formatted_address"),
                    "google_maps_url": details_data.get("url"),
                    "google_phone": details_data.get("formatted_phone_number"),
                    "google_website": details_data.get("website"),
                    "opening_hours": details_data.get("opening_hours", {}).get("weekday_text", []),
                    "lat": candidate.get("geometry", {}).get("location", {}).get("lat"),
                    "lng": candidate.get("geometry", {}).get("location", {}).get("lng")
                }

        except Exception as e:
            logger.error(f"❌ Google Maps API Error: {e}")
            return None

google_maps_service = GoogleMapsService()
