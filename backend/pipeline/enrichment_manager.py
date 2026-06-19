import asyncio
import logging
from services.google_maps_service import google_maps_service
from services.wikipedia_service import wikipedia_service
from services.osm_service import osm_service
from services.image_repair_service import image_repair_service
from mas.supervisor import supervisor as mas_supervisor

logger = logging.getLogger("EnrichmentManager")

class EnrichmentManager:
    async def enrich_all(self, extracted_data: dict) -> dict:
        """
        Runs multiple enrichment services in parallel and merges results.
        Ensures high-fidelity data before final validation.
        """
        name = extracted_data.get("name")
        if not name:
            return extracted_data

        logger.info(f"🧪 [Enrichment] Orchestrating intelligence for: {name}")

        # Phase 1: Sequential Dependency (Google Maps for Lat/Lng)
        # We need coordinates before we can do OSM.
        g_data = await google_maps_service.find_place_details(name)
        if g_data:
            extracted_data["google_metadata"] = {
                "place_id": g_data["google_place_id"],
                "rating": g_data["google_rating"],
                "user_ratings_total": g_data["google_user_ratings_total"],
                "maps_url": g_data["google_maps_url"],
                "phone": g_data["google_phone"],
                "website": g_data["google_website"],
                "opening_hours": g_data.get("opening_hours", [])
            }
            if g_data.get("lat") and g_data.get("lng"):
                extracted_data["lat"] = g_data["lat"]
                extracted_data["lng"] = g_data["lng"]

        # Phase 2: Parallel Enrichment (Wiki + OSM)
        # Using latitude and longitude from Phase 1 for OSM
        lat, lng = extracted_data.get("lat"), extracted_data.get("lng")
        
        tasks = [
            wikipedia_service.get_summary(name),
            osm_service.get_nearby_amenities(lat, lng) if lat and lng else asyncio.sleep(0, result=[])
        ]
        
        wiki_res, osm_res = await asyncio.gather(*tasks)
        
        if wiki_res:
            extracted_data["wiki_summary"] = wiki_res
            logger.info(f"✅ [Enrichment] Wiki summary attached for {name}")

        if osm_res:
            extracted_data["nearby_facilities"] = osm_res
            logger.info(f"✅ [Enrichment] {len(osm_res)} OSM facilities mapped for {name}")

        # Phase 3: Visual Integrity Service
        # We don't block the UI, but we trigger the repair/validation logic
        logger.info(f"🎨 [Enrichment] Triggering Visual Integrity engine for: {name}")
        # Note: In a production flow, this might be backgrounded
        asyncio.create_task(image_repair_service.repair_place_image(extracted_data.get("uuid", name)))

        return extracted_data

    async def enrich_with_mas(self, place_name: str, district: str) -> dict:
        """
        Uses the Multi-Agent System (LangGraph) for high-fidelity investigation.
        """
        logger.info(f"🚀 [Enrichment] UNLEASHING MAS for: {place_name}")
        result = await mas_supervisor.execute(place_name, district)
        return result.get("final_result", {})

enrichment_manager = EnrichmentManager()
