from core.mongodb import get_mongo_db
from typing import List, Dict, Any, Optional

async def get_all_places() -> List[Dict[str, Any]]:
    db = await get_mongo_db()
    # Basic query to get places. MongoDB places store image data inside the document.
    cursor = db.places.find({"status": "approved"}).sort("created_at", -1)
    places = await cursor.to_list(length=100)
    
    # Process for UI compatibility (ensure id is string)
    for p in places:
        p["id"] = str(p.get("_id", ""))
        p["cover_image"] = p.get("external_image_url") # Fallback to external url if no local
        if p.get("images") and len(p["images"]) > 0:
            p["cover_image"] = p["images"][0].get("image_path")
            
    return places

async def get_place_by_id(place_id: str) -> Optional[Dict[str, Any]]:
    db = await get_mongo_db()
    # Try finding by smart_id or uuid or _id
    from bson import ObjectId
    
    query = {"$or": [
        {"smart_id": place_id},
        {"uuid": place_id}
    ]}
    
    try:
        if ObjectId.is_valid(place_id):
            query["$or"].append({"_id": ObjectId(place_id)})
    except:
        pass
        
    place = await db.places.find_one(query)
    
    if not place:
        return None
        
    place["id"] = str(place["_id"])
    return place
