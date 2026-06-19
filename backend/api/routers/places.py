from fastapi import APIRouter, Depends, HTTPException, Request, Form, File, UploadFile
from core.security import get_current_user
from core.rate_limit import limiter
from services.place_service import get_all_places, get_place_by_id
from services.masking_service import mask_place
from services.image_service import process_image
from core.mongodb import get_mongo_db
from typing import List, Union, Optional
import uuid
import json
from datetime import datetime
from bson import ObjectId

router = APIRouter(prefix="/api", tags=["places"])

@router.get("/places/map", response_model=List[dict])
async def list_places_for_map():
    """Returns approved places with coordinates for mapping."""
    db = await get_mongo_db()
    cursor = db.places.find(
        {"status": "approved", "lat": {"$ne": None}, "lng": {"$ne": None}},
        {"id": 1, "name": 1, "lat": 1, "lng": 1, "category_id": 1, "district_id": 1, "images": 1}
    )
    places = await cursor.to_list(length=1000)
    
    results = []
    for p in places:
        thumbnail = None
        if p.get("images"):
            cover = next((img for img in p["images"] if img.get("is_cover")), p["images"][0])
            thumbnail = cover.get("image_path")

        results.append({
            "id": str(p["_id"]),
            "name": p["name"],
            "lat": p["lat"],
            "lng": p["lng"],
            "category_id": p.get("category_id"),
            "district_id": p.get("district_id"),
            "thumbnail": thumbnail
        })
    return results

@router.get("/places", response_model=List[dict])
@limiter.limit("20/minute")
async def list_places(request: Request, user=Depends(get_current_user)):
    """Returns places filtered by user tier."""
    places = await get_all_places()
    tier = user.get("tier", "anonymous")
    
    if tier == "anonymous":
        places = places[:20]
    elif tier in ["free", "verified"]:
        places = places[:50]
        
    return [mask_place(place, user) for place in places]

@router.get("/places/{place_id}", response_model=dict)
@limiter.limit("30/minute")
async def get_place_detail(place_id: str, request: Request, user=Depends(get_current_user)):
    """Returns detailed information for a specific place."""
    place = await get_place_by_id(place_id)
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
    return mask_place(place, user)

@router.post("/places")
async def add_place(
    request: Request,
    name: str = Form(...),
    country: str = Form("Sri Lanka"),
    district_id: str = Form(...),
    category_id: str = Form(...),
    description: str = Form(""),
    lat: str = Form(""),
    lng: str = Form(""),
    user_context=Depends(get_current_user),
):
    db = await get_mongo_db()
    
    # Duplicate check
    existing = await db.places.find_one({"name": name, "district_id": district_id})
    if existing:
        raise HTTPException(status_code=409, detail="Place already exists in this district.")

    place_uuid = str(uuid.uuid4())
    now = datetime.utcnow()

    new_place = {
        "uuid": place_uuid,
        "name": name,
        "country": country,
        "district_id": district_id,
        "category_id": category_id,
        "description": description,
        "lat": float(lat) if lat else None,
        "lng": float(lng) if lng else None,
        "status": "pending_review",
        "created_at": now,
        "updated_at": now,
        "images": []
    }
    
    result = await db.places.insert_one(new_place)
    return {"id": str(result.inserted_id), "message": "Place created successfully"}

@router.patch("/places/{place_id}")
async def update_place(place_id: str, request: Request, user_context=Depends(get_current_user)):
    data = await request.json()
    db = await get_mongo_db()
    
    query = {"$or": [{"uuid": place_id}]}
    if ObjectId.is_valid(place_id):
        query["$or"].append({"_id": ObjectId(place_id)})

    update_data = {k: v for k, v in data.items() if k != "id" and k != "_id"}
    update_data["updated_at"] = datetime.utcnow()

    result = await db.places.update_one(query, {"$set": update_data})
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Place not found")
        
    return {"message": "Place updated successfully"}
