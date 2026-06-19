import asyncio
import logging
import sys
import os

# Adjust path to import backend modules
sys.path.append(os.getcwd())

from pipeline.search_engine import search_engine
from pipeline.enrichment_manager import enrichment_manager
from core.mongodb import get_mongo_db
from pipeline.ai_extractor import AIExtractor

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("DistrictDiscovery")

class DistrictDiscoveryAgent:
    def __init__(self):
        self.extractor = AIExtractor()

    async def discover_district(self, district_name: str):
        """
        Deep dives into a district to find and ingest all relevant tourism sites.
        """
        logger.info(f"📍 [DistrictDiscovery] Starting deep dive for: {district_name}")
        
        # 1. Search for potential place names
        query = f"top tourist attractions, historical sites, beaches, and nature spots in {district_name} district Sri Lanka"
        results = await search_engine.search_web(query)
        
        if not results:
            logger.error(f"❌ [DistrictDiscovery] No search results for {district_name}")
            return []

        # 2. Extract specific place names from search text using AI
        combined_text = "\n".join([r.get('body', '') for r in results[:10]])
        prompt = f"""Identify exactly 15 unique, high-value tourism place names in {district_name} district from this text:
        {combined_text}
        Return ONLY a JSON list of strings."""
        
        # We use a simple prompt for name extraction
        try:
            place_names = await self.extractor.extract_names_batch(prompt) or []
        except:
            # Fallback if AI fails, just use generic search queries
            place_names = [district_name + " attractions"] # Minimal fallback
            
        logger.info(f"🔎 [DistrictDiscovery] Identified {len(place_names)} potential sites: {place_names}")

        # 3. Process each place found
        discovered_count = 0
        for name in place_names:
            logger.info(f"🚀 [DistrictDiscovery] Processing discovered site: {name}")
            try:
                # Direct enrichment for the name
                data = await enrichment_manager.enrich_all(name, district_name)
                if data:
                    discovered_count += 1
                    logger.info(f"✅ [DistrictDiscovery] Successfully ingested: {name}")
            except Exception as e:
                logger.error(f"❌ [DistrictDiscovery] Failed to ingest {name}: {e}")
            
            # Throttle
            await asyncio.sleep(1)

        logger.info(f"🏁 [DistrictDiscovery] Completed {district_name}. Ingested {discovered_count} sites.")
        return place_names

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python pipeline/district_discovery.py <DistrictName>")
        sys.exit(1)
    
    district = sys.argv[1]
    agent = DistrictDiscoveryAgent()
    asyncio.run(agent.discover_district(district))
