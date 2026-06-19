import overpy
import json
import logging
import asyncio
import aiohttp
from pathlib import Path
from bs4 import BeautifulSoup
from discovery.universal_discovery_hive import UniversalDiscoveryHive

# Configure Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("TankDiscovery")

class TankDiscoveryBot:
    def __init__(self):
        self.api = overpy.Overpass()
        self.output_dir = Path("data/discovery")
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.output_file = self.output_dir / "discovered_tanks.json"
        self.hive = UniversalDiscoveryHive()

    async def discover_via_osm(self) -> list[dict]:
        """
        Query OpenStreetMap (OSM) Overpass API for all reservoirs/tanks in Sri Lanka.
        Filters for 'natural=water' + 'water=reservoir' or named 'Wewa'.
        """
        logger.info("🌍 Querying OpenStreetMap for Sri Lankan Tanks...")
        
        # Overpass query: Find all water bodies tagged as reservoirs in SL
        query = """
        [out:json][timeout:90];
        area["name"="Sri Lanka"]->.searchArea;
        (
          node["water"="reservoir"](area.searchArea);
          way["water"="reservoir"](area.searchArea);
          relation["water"="reservoir"](area.searchArea);
          node["name"~"Wewa"](area.searchArea);
          way["name"~"Wewa"](area.searchArea);
        );
        out body;
        >;
        out skel qt;
        """
        
        try:
            # Overpy is synchronous, but we wrap it for consistency
            result = await asyncio.to_thread(self.api.query, query)
            
            tanks = []
            for way in result.ways:
                name = way.tags.get("name", "Unknown Tank")
                if not name or name == "Unknown Tank": continue
                
                tanks.append({
                    "name": name,
                    "type": "tank",
                    "source": "osm",
                    "osm_id": way.id,
                    "lat": float(way.center_lat) if way.center_lat else None,
                    "lon": float(way.center_lon) if way.center_lon else None,
                    "tags": dict(way.tags),
                    "search_query": f"{name} Sri Lanka"
                })
            
            logger.info(f"✅ OSM Discovery found {len(tanks)} tanks.")
            return tanks
        except Exception as e:
            logger.error(f"❌ OSM Query failed: {e}")
            return []

    async def discover_via_wikipedia(self) -> list[dict]:
        """
        Scrape Wikipedia categories for major Sri Lankan reservoirs.
        Ensures we get URLs for high-quality extraction.
        """
        logger.info("📚 Scraping Wikipedia for Major Reservoirs...")
        wiki_url = "https://en.wikipedia.org/wiki/Category:Reservoirs_in_Sri_Lanka"
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(wiki_url) as response:
                    if response.status != 200: return []
                    html = await response.text()
                    soup = BeautifulSoup(html, "html.parser")
                    
                    category_div = soup.find("div", id="mw-pages")
                    if not category_div: return []
                    
                    links = category_div.find_all("a")
                    wiki_tanks = []
                    for link in links:
                        title = link.get("title")
                        href = link.get("href")
                        if title and href and not ":" in title:
                            wiki_tanks.append({
                                "name": title,
                                "type": "tank",
                                "source": "wikipedia",
                                "url": f"https://en.wikipedia.org{href}",
                                "priority": "high"
                            })
                    
                    logger.info(f"✅ Wikipedia Discovery found {len(wiki_tanks)} major tanks.")
                    return wiki_tanks
        except Exception as e:
            logger.error(f"❌ Wiki Discovery failed: {e}")
            return []

    async def run_smart_hive(self):
        """Run the AI-driven universal discovery hive."""
        logger.info("🧠 Switching to Universal AI Discovery Hive...")
        # We trigger the master hive (all categories)
        return await self.hive.run_master_hive()

    async def run_discovery_hive(self, mode="hybrid"):
        """Orchestrate all discovery sources and deduplicate."""
        if mode == "smart":
            return await self.run_smart_hive()

        # Run in parallel
        osm_task = self.discover_via_osm()
        wiki_task = self.discover_via_wikipedia()
        
        osm_results, wiki_results = await asyncio.gather(osm_task, wiki_task)
        
        # Merge & Deduplicate
        all_tanks = {}
        
        # Priority 1: Wiki (Better metadata)
        for tank in wiki_results:
            all_tanks[tank['name'].lower()] = tank
            
        # Priority 2: OSM (Massive volume)
        for tank in osm_results:
            name_key = tank['name'].lower()
            if name_key not in all_tanks:
                all_tanks[name_key] = tank
            else:
                # Merge OSM coordinates into Wiki entry
                all_tanks[name_key]['lat'] = tank.get('lat')
                all_tanks[name_key]['lon'] = tank.get('lon')
                all_tanks[name_key]['osm_tags'] = tank.get('tags')

        final_list = list(all_tanks.values())
        
        with open(self.output_file, "w", encoding="utf-8") as f:
            json.dump(final_list, f, indent=2, ensure_ascii=False)
            
        logger.info(f"🚀 Discovery Hive Complete! Total Unique Tanks: {len(final_list)}")
        print(f"\n[SUMMARY] Saved {len(final_list)} tanks to {self.output_file}")
        return final_list

if __name__ == "__main__":
    import sys
    mode = sys.argv[1] if len(sys.argv) > 1 else "hybrid"
    bot = TankDiscoveryBot()
    asyncio.run(bot.run_discovery_hive(mode=mode))
