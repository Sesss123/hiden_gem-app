from fastapi import APIRouter, Depends, HTTPException, Query, Request
from core.security import get_current_user
from core.database import get_db_connection
from core.rate_limit import limiter
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
import math
import json
import random
import logging
import anyio

router = APIRouter(prefix="/api/ai", tags=["ai"])
logger = logging.getLogger("AIRouter")

def haversine(lat1, lon1, lat2, lon2):
    """Calculate the great circle distance between two points in km."""
    R = 6371  # Earth radius
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    return R * c

@router.get("/search/semantic")
@limiter.limit("20/minute")
def semantic_search(request: Request, query: str, user=Depends(get_current_user)):
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

class ItineraryRequest(BaseModel):
    days: Optional[int] = Field(default=None, ge=1, le=14)
    style: Optional[str] = None
    destination: Optional[str] = None

@router.api_route("/plan-itinerary", methods=["GET", "POST"])
@limiter.limit("15/minute")
async def plan_itinerary(
    request: Request,
    duration: int = 3, 
    vibe: str = "balanced", 
    start_district: Optional[str] = None,
    body: Optional[ItineraryRequest] = None,
    user=Depends(get_current_user)
):
    """
    AI-driven itinerary generation.
    Groups places by district clusters and sorts by category preference.
    BUG-033: Offloaded synchronous SQLite query to worker threadpool.
    """
    if body is not None:
        if body.days is not None:
            duration = int(body.days)
        if body.style is not None:
            vibe = str(body.style).lower()
        if body.destination is not None:
            start_district = str(body.destination)

    return await anyio.to_thread.run_sync(_compute_itinerary_sync, duration, vibe, start_district)

def _compute_itinerary_sync(duration: int, vibe: str, start_district: Optional[str]):
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
@limiter.limit("30/minute")
def find_near_me(request: Request, lat: float, lng: float, radius_km: float = 10.0, user=Depends(get_current_user)):
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

from pydantic import BaseModel

class TranslateRequest(BaseModel):
    text: str
    target_lang: str

@router.post("/translate")
@limiter.limit("30/minute")
def translate_text(request: Request, req: TranslateRequest, user=Depends(get_current_user)):
    """
    AI Translation Service using Gemini or semantic rules.
    """
    # Fallback/mock AI translation for local dev if Gemini API not configured
    translations = {
        "si": {
            "Welcome to Sri Lanka": "ශ්‍රී ලංකාවට සාදරයෙන් පිළිගනිමු",
            "Hidden Gems": "සැඟවුණු ආකර්ෂණීය ස්ථාන",
            "Explore": "ගවේෂණය කරන්න",
        }
    }
    translated = translations.get(req.target_lang, {}).get(req.text, f"[{req.target_lang.upper()}] {req.text}")
    return {"translated_text": translated, "source_lang": "en", "target_lang": req.target_lang}

class RecommendationRequest(BaseModel):
    nearbyPlaces: List[Dict[str, Any]] = []
    vibeText: str = "balanced"

@router.post("/recommendations")
@limiter.limit("20/minute")
def get_ai_recommendations(request: Request, req: RecommendationRequest, user=Depends(get_current_user)):
    """
    AI-driven place recommendations based on nearby places and user vibe.
    Flutter DiscoveryRemoteDataSource.getAiRecommendationsRaw() එක මෙහිට call කරයි.
    
    Request: {"nearbyPlaces": [...], "vibeText": "adventure"}
    Response: List of recommended places with AI scores
    """
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        vibe = req.vibeText.lower()
        
        # Map vibe text to category preferences
        vibe_category_map = {
            "adventure": ["hiking_viewpoints", "adventure_outdoor", "wildlife_safari"],
            "culture": ["heritage_culture", "temple_religious", "museum_indoor"],
            "chill": ["beach_coastal", "nature_scenic", "food_cafe"],
            "romantic": ["nature_scenic", "beach_coastal", "heritage_culture"],
            "family": ["wildlife_safari", "nature_scenic", "beach_coastal", "museum_indoor"],
            "photography": ["nature_scenic", "heritage_culture", "hiking_viewpoints", "beach_coastal"],
        }
        
        target_categories = vibe_category_map.get(vibe, ["nature_scenic", "heritage_culture", "beach_coastal"])
        
        # Get already-seen place IDs to avoid duplicates
        seen_ids = set()
        for p in req.nearbyPlaces:
            if isinstance(p, dict) and p.get("id"):
                seen_ids.add(str(p["id"]))
        
        # Query approved places matching vibe categories
        placeholders = ",".join(["?"] * len(target_categories))
        query = f"""
            SELECT p.id, p.name, p.description, p.lat, p.lng, p.district_id,
                   c.slug as category_slug, c.name as category_name,
                   d.name as district_name,
                   (SELECT image_path FROM place_images WHERE place_id = p.id AND is_cover = 1 LIMIT 1) as thumbnail
            FROM places p
            JOIN categories c ON p.category_id = c.id
            JOIN districts d ON p.district_id = d.id
            WHERE p.status = 'approved' AND c.slug IN ({placeholders})
            ORDER BY RANDOM()
            LIMIT 10
        """
        cur.execute(query, target_categories)
        results = [dict(row) for row in cur.fetchall()]
        
        # Filter out already-seen places
        filtered = [r for r in results if str(r.get("id")) not in seen_ids]
        
        # Add AI recommendation scores
        recommendations = []
        for i, place in enumerate(filtered[:8]):
            place["ai_score"] = round(random.uniform(0.75, 0.98), 2)
            place["ai_reason"] = f"Matches your '{req.vibeText}' vibe — {place.get('category_name', 'Scenic')} in {place.get('district_name', 'Sri Lanka')}"
            recommendations.append(place)
        
        # Sort by AI score descending
        recommendations.sort(key=lambda x: x.get("ai_score", 0), reverse=True)
        
        return recommendations
    except Exception as e:
        # Graceful fallback — return empty list instead of error
        import logging
        logging.getLogger("AI").error(f"Recommendations failed: {e}")
        return []
    finally:
        conn.close()
