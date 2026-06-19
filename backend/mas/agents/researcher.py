import logging
from typing import Dict, Any
from mas.state import AgentState
from services.google_maps_service import google_maps_service
from services.wikipedia_service import wikipedia_service
from services.osm_service import osm_service
from services.telemetry_service import telemetry_service
from duckduckgo_search import DDGS

logger = logging.getLogger("ResearchAgent")

class ResearchAgent:
    async def run(self, state: AgentState) -> Dict[str, Any]:
        """
        Gathers raw data from multiple sources.
        """
        name = state["destination_name"]
        district = state.get("district", "Sri Lanka")
        
        logger.info(f"🔍 [ResearchAgent] Investigating: {name} in {district}")
        
        await telemetry_service.update_agent_status(
            "Researcher", "Initializing", f"Searching for {name} in {district}..."
        )
        g_data = await google_maps_service.find_place_details(name, district)
        
        # 2. Parallel Search (Wiki + Web)
        search_query = f"{name} {district} ticket prices opening hours Sri Lanka"
        
        wiki_task = wikipedia_service.get_summary(name)
        web_search_task = self._web_search(search_query)
        
        # Gathering coordinates for OSM
        lat = g_data.get("lat") if g_data else None
        lng = g_data.get("lng") if g_data else None
        
        osm_task = osm_service.get_nearby_amenities(lat, lng) if lat and lng else None
        
        # Execute parallel tasks
        wiki_res = await wiki_task
        web_res = await web_search_task
        osm_res = await osm_task if osm_task else []
        
        # Compile result
        raw_data = {
            "google": g_data,
            "wikipedia": wiki_res,
            "web_search": web_res,
            "osm_facilities": osm_res,
            "coords": {"lat": lat, "lng": lng}
        }
        
        log_entry = {
            "agent": "Researcher",
            "action": "Data Harvesting",
            "reasoning": f"Gathered coordinates from G-Maps, summary from Wikipedia, and current situational data via DuckDuckGo search. Found {len(osm_res)} nearby facilities via OSM."
        }
        
        await telemetry_service.update_agent_status(
            "Researcher", "Data Harvesting", log_entry["reasoning"]
        )
        
        return {
            "raw_data": raw_data,
            "reasoning_logs": [log_entry],
            "history": ["research_complete"]
        }

    async def _web_search(self, query: str) -> str:
        """Uses DuckDuckGo to find real-time info like prices and timings."""
        try:
            with DDGS() as ddgs:
                results = [r for r in ddgs.text(query, max_results=5)]
                summary = "\n".join([f"- {r['title']}: {r['body']}" for r in results])
                return summary
        except Exception as e:
            logger.error(f"❌ Web Search failed: {e}")
            return "Web search unavailable."

researcher = ResearchAgent()
