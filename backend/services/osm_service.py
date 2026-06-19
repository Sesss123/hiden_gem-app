import httpx
import logging

logger = logging.getLogger("OSMService")

class OSMService:
    def __init__(self):
        self.overpass_url = "https://overpass-api.de/api/interpreter"

    async def get_nearby_amenities(self, lat: float, lng: float, radius: int = 1500):
        """
        Fetch nearby amenities (restaurants, cafes, hospitals, transport) 
        from OpenStreetMap via Overpass API.
        """
        if not lat or not lng:
            return []

        # Query for points of interest within radius
        query = f"""
        [out:json];
        (
          node["amenity"~"restaurant|cafe|hospital|atm|fuel"](around:{radius},{lat},{lng});
          node["highway"~"bus_stop"](around:{radius},{lat},{lng});
          node["tourism"~"information|viewpoint"](around:{radius},{lat},{lng});
        );
        out body;
        """
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(self.overpass_url, data={"data": query}, timeout=30.0)
                data = response.json()
                
                elements = data.get("elements", [])
                results = []
                
                for el in elements:
                    tags = el.get("tags", {})
                    results.append({
                        "id": el.get("id"),
                        "name": tags.get("name", "Unknown"),
                        "type": tags.get("amenity") or tags.get("highway") or tags.get("tourism"),
                        "lat": el.get("lat"),
                        "lng": el.get("lon"),
                        "distance": radius # Simplified, could calculate exact distance if needed
                    })
                
                # Sort and limit to top 15 results
                return sorted(results, key=lambda x: x['name'])[:15]
        except Exception as e:
            logger.error(f"❌ OSM Overpass API Error: {e}")
            return []

    async def verify_tank_by_name(self, name: str, district: str = None) -> dict | None:
        """
        Verify if a name exists in OSM as a reservoir/tank.
        """
        area_filter = f'area["name"="{district} District"]->.searchArea;' if district else 'area["name"="Sri Lanka"]->.searchArea;'
        query = f"""
        [out:json][timeout:25];
        {area_filter}
        (
          node["name"~"{name}", i](area.searchArea);
          way["name"~"{name}", i](area.searchArea);
          relation["name"~"{name}", i](area.searchArea);
        );
        out body;
        >;
        out skel qt;
        """
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(self.overpass_url, data={"data": query}, timeout=30.0)
                data = response.json()
                elements = data.get("elements", [])
                
                # Filter for water bodies
                for el in elements:
                    tags = el.get("tags", {})
                    is_water = any(t in str(tags).lower() for t in ["reservoir", "water", "lake", "wewa", "kulam"])
                    if is_water:
                        return {
                            "osm_id": el.get("id"),
                            "lat": el.get("lat") or el.get("center", {}).get("lat"),
                            "lng": el.get("lon") or el.get("center", {}).get("lon"),
                            "tags": tags
                        }
                return None
        except Exception as e:
            logger.error(f"❌ OSM Verification Error: {e}")
            return None

osm_service = OSMService()
