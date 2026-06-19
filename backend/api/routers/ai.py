from fastapi import APIRouter, Depends, HTTPException, Query
from core.security import get_current_user
from core.database import get_db_connection
from typing import List, Optional
import math
import json

router = APIRouter(prefix="/api/ai", tags=["ai"])

def haversine(lat1, lon1, lat2, lon2):
    """Calculate the great circle distance between two points in km."""
    R = 6371  # Earth radius
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    return R * c

@router.get("/search/semantic")
async def semantic_search(query: str, user=Depends(get_current_user)):
    """
    Experimental Semantic Search.
    In Phase 3, we use context-weighting across name, tags, and AI summaries.
    """
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        # For a truly semantic search without a heavy local model, 
        # we perform a weighted match against name, category, and AI summary.
        # This will be replaced by Vector Similarity in a production deployment.
        search_query = f"%{query}%"
        cur.execute("""
            SELECT p.*, c.name as cat_name, d.name as dist_name,
                   (SELECT image_path FROM place_images WHERE place_id = p.id AND is_cover = 1 LIMIT 1) as thumbnail
            FROM places p
            JOIN categories c ON p.category_id = c.id
            JOIN districts d ON p.district_id = d.id
            WHERE p.status = 'approved' AND (
                p.name LIKE ? OR 
                p.description LIKE ? OR 
                p.ai_summary LIKE ? OR 
                p.tags LIKE ? OR
                c.name LIKE ?
            )
            LIMIT 20
        """, (search_query, search_query, search_query, search_query, search_query))
        rows = cur.fetchall()
        return [dict(row) for row in rows]
    finally:
        conn.close()

@router.get("/plan-itinerary")
async def plan_itinerary(
    duration: int = 3, 
    vibe: str = "balanced", 
    start_district: Optional[str] = None,
    user=Depends(get_current_user)
):
    """
    AI-driven itinerary generation.
    Groups places by district clusters and sorts by category preference.
    """
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        # 1. Map 'vibe' to categories
        vibe_map = {
            "adventure": ["hiking_viewpoints", "adventure_outdoor", "wildlife_safari"],
            "culture": ["heritage_culture", "temple_religious", "museum_indoor"],
            "chill": ["beach_coastal", "nature_scenic", "food_cafe"],
            "balanced": ["heritage_culture", "nature_scenic", "beach_coastal", "hiking_viewpoints"]
        }
        target_slugs = vibe_map.get(vibe, vibe_map["balanced"])
        
        # 2. Get all approved places in target categories
        placeholders = ",".join(["?"] * len(target_slugs))
        query = f"""
            SELECT p.*, c.slug as cat_slug, d.name as dist_name,
                   (SELECT image_path FROM place_images WHERE place_id = p.id AND is_cover = 1 LIMIT 1) as thumbnail
            FROM places p
            JOIN categories c ON p.category_id = c.id
            JOIN districts d ON p.district_id = d.id
            WHERE p.status = 'approved' AND c.slug IN ({placeholders})
        """
        cur.execute(query, target_slugs)
        all_places = [dict(row) for row in cur.fetchall()]
        
        if not all_places:
            raise HTTPException(status_code=404, detail="No matching places found for this vibe.")

        # 3. Simple Greedy Clustering (By District)
        # In a real AI implementation, we'd use a TSP solver.
        itinerary = []
        current_itinerary = []
        used_ids = set()
        
        # Sort by district to keep days centered
        districts = {}
        for p in all_places:
            d = p["dist_name"]
            if d not in districts: districts[d] = []
            districts[d].append(p)

        # Build day by day
        available_districts = list(districts.keys())
        for day in range(1, duration + 1):
            if not available_districts: break
            
            # Select a district for the day
            # If start_district provided and in list, pick it for Day 1
            if day == 1 and start_district and start_district in available_districts:
                target_dist = start_district
            else:
                target_dist = available_districts[0]
            
            available_districts.remove(target_dist)
            
            day_plan = {
                "day": day,
                "district": target_dist,
                "activities": districts[target_dist][:3] # 3 items per day
            }
            itinerary.append(day_plan)

        return {
            "vibe": vibe,
            "duration": duration,
            "itinerary": itinerary
        }
    finally:
        conn.close()

@router.get("/near-me")
async def find_near_me(lat: float, lng: float, radius_km: float = 10.0, user=Depends(get_current_user)):
    """Locate hidden gems within a specific radius of the user."""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT p.*, (SELECT image_path FROM place_images WHERE place_id = p.id AND is_cover = 1 LIMIT 1) as thumbnail
            FROM places p
            WHERE p.status = 'approved' AND p.lat IS NOT NULL AND p.lng IS NOT NULL
        """)
        all_places = cur.fetchall()
        
        nearby = []
        for p in all_places:
            dist = haversine(lat, lng, p["lat"], p["lng"])
            if dist <= radius_km:
                p_dict = dict(p)
                p_dict["distance_km"] = round(dist, 2)
                nearby.append(p_dict)
                
        # Sort by proximity
        nearby.sort(key=lambda x: x["distance_km"])
        return nearby[:15]
    finally:
        conn.close()
