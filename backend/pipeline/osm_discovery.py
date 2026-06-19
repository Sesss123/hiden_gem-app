# backend/pipeline/osm_discovery.py

import json
import logging
import asyncio
import overpy
from typing import List, Dict, Any
from pathlib import Path

# Configure Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("OSMDiscovery")

class OSMDiscoveryEngine:
    def __init__(self):
        self.api = overpy.Overpass()
        self.output_dir = Path("data/discovery")
        self.output_dir.mkdir(parents=True, exist_ok=True)

    async def query_osm(self, category: str) -> List[Dict[str, Any]]:
        """
        Query OSM for specific categories.
        Supported categories: 'waterfall', 'peak', 'viewpoint', 'monument', 'temple', 'attraction'
        """
        logger.info(f"[OSMDiscovery] 🌍 Querying OpenStreetMap for category: {category}...")
        
        # Mapping categories to OSM tags
        category_map = {
            "waterfall": 'node["waterway"="waterfall"]',
            "peak": 'node["natural"="peak"]',
            "viewpoint": 'node["tourism"="viewpoint"]',
            "monument": 'node["historic"="monument"]',
            "temple": 'node["amenity"="place_of_worship"]["religion"="buddhist"]',
            "attraction": 'node["tourism"="attraction"]'
        }

        tag_query = category_map.get(category.lower(), category_map["attraction"])
        
        # Overpass query: Find entities in Sri Lanka
        query = f"""
        [out:json][timeout:90];
        area["name"="Sri Lanka"]->.searchArea;
        (
          {tag_query}(area.searchArea);
          way(picker)["tourism"="attraction"](area.searchArea);
        );
        out body;
        >;
        out skel qt;
        """
        
        # Fixed query for better reliability
        query = f"""
        [out:json][timeout:60];
        area["name"="Sri Lanka"]->.searchArea;
        (
          {tag_query}(area.searchArea);
        );
        out body;
        >;
        out skel qt;
        """
        
        try:
            result = await asyncio.to_thread(self.api.query, query)
            
            items = []
            for node in result.nodes:
                name = node.tags.get("name")
                if not name: continue
                
                items.append({
                    "name": name,
                    "category": category,
                    "source": "osm",
                    "lat": float(node.lat),
                    "lon": float(node.lon),
                    "osm_id": node.id,
                    "tags": dict(node.tags),
                    "type": "hidden_gem"
                })
            
            logger.info(f"✅ OSM Discovery found {len(items)} items for {category}.")
            return items
        except Exception as e:
            logger.error(f"❌ OSM Query failed for {category}: {e}")
            return []

    async def discover_all_natural_gems(self) -> List[Dict[str, Any]]:
        """Run discovery for all natural and heritage categories."""
        categories = ["waterfall", "peak", "viewpoint", "monument", "temple"]
        tasks = [self.query_osm(cat) for cat in categories]
        
        results = await asyncio.gather(*tasks)
        
        all_gems = []
        for res in results:
            all_gems.extend(res)
            
        # Deduplicate by name and proximity (simplified by name)
        unique_gems = {}
        for gem in all_gems:
            key = gem['name'].lower().strip()
            if key not in unique_gems:
                unique_gems[key] = gem
                
        final_list = list(unique_gems.values())
        logger.info(f"🚀 OSM Discovery Complete! Total Unique Gems: {len(final_list)}")
        return final_list

# Singleton instance
osm_discovery = OSMDiscoveryEngine()

if __name__ == "__main__":
    async def main():
        gems = await osm_discovery.discover_all_natural_gems()
        print(f"Found {len(gems)} items.")
        if gems:
            print(f"Example: {gems[0]['name']} at {gems[0]['lat']}, {gems[0]['lon']}")
            
    asyncio.run(main())
