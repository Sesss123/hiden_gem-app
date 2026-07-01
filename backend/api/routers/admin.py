from fastapi import APIRouter, Depends, HTTPException, Query, Response, Request
from core.security import get_current_user
from core.rate_limit import limiter
from core.mongodb import get_mongo_db
from schemas.admin_schemas import PipelineRunSchema, AdminAnalyticsSchema, BulkActionRequest
from typing import List, Optional
import csv
import io
import json
from datetime import datetime
import os
from pathlib import Path
from scripts.system_guard import SystemGuard

router = APIRouter(prefix="/api/admin", tags=["admin"])

@router.get("/pipeline-history", response_model=List[PipelineRunSchema])
async def get_pipeline_history(user=Depends(get_current_user)):
    """Retrieve historical pipeline runs from MongoDB."""
    if user.get("role") != "admin" and user.get("tier") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required.")
        
    db = await get_mongo_db()
    cursor = db.pipeline_runs.find().sort("start_time", -1)
    runs = await cursor.to_list(length=100)
    # Convert MongoDB _id if needed or use 'id' field
    return runs

@router.post("/places/bulk-action")
async def bulk_action(request: BulkActionRequest, user=Depends(get_current_user)):
    """Perform bulk operations on selected places in MongoDB."""
    if user.get("role") != "admin" and user.get("tier") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required.")
        
    db = await get_mongo_db()
    if not request.ids:
        return {"message": "No places selected."}
    
    from bson import ObjectId
    obj_ids = []
    uuids = []
    for id_val in request.ids:
        if ObjectId.is_valid(id_val):
            obj_ids.append(ObjectId(id_val))
        else:
            uuids.append(id_val)

    filter_query = {"$or": [
        {"_id": {"$in": obj_ids}},
        {"uuid": {"$in": uuids}},
        {"smart_id": {"$in": uuids}}
    ]}
    
    if request.action == "approve":
        await db.places.update_many(filter_query, {"$set": {"status": "approved", "approved": 1, "updated_at": datetime.utcnow()}})
    elif request.action == "reject":
        await db.places.update_many(filter_query, {"$set": {"status": "rejected", "approved": -1, "updated_at": datetime.utcnow()}})
    elif request.action == "delete":
        await db.places.delete_many(filter_query)
    elif request.action == "change_category":
        if not request.value:
            raise HTTPException(status_code=400, detail="Category ID is required.")
        await db.places.update_many(filter_query, {"$set": {"category_id": request.value, "updated_at": datetime.utcnow()}})
    else:
        raise HTTPException(status_code=400, detail="Invalid action.")
        
    return {"message": f"Bulk {request.action} successful.", "count": len(request.ids)}

@router.get("/analytics/overview", response_model=AdminAnalyticsSchema)
async def get_analytics_overview(user=Depends(get_current_user)):
    """Aggregate stats from MongoDB: Visitor logs, Pipeline runs, and AI Usage."""
    if user.get("role") != "admin" and user.get("tier") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required.")
        
    db = await get_mongo_db()
    
    # 1. Total Views (from visitor_analytics)
    total_views = await db.visitor_analytics.count_documents({"type": "view"})
    
    # 2. Top Places
    pipeline = [
        {"$match": {"type": "view"}},
        {"$group": {"_id": "$place_id", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 10}
    ]
    top_entries = await db.visitor_analytics.aggregate(pipeline).to_list(length=10)
    top_places = []
    for entry in top_entries:
        # Fetch name from places
        place = await db.places.find_one({"slug": entry["_id"]})
        top_places.append({
            "place_id": str(entry["_id"]) if entry.get("_id") is not None else None,
            "name": place["name"] if place else "Unknown",
            "view_count": entry["count"]
        })

    # 3. Popular Searches
    pipeline_search = [
        {"$match": {"type": "search", "search_term": {"$ne": None}}},
        {"$group": {"_id": "$search_term", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 10}
    ]
    popular_searches = await db.visitor_analytics.aggregate(pipeline_search).to_list(length=10)
    popular_searches = [{"term": str(s["_id"]) if s.get("_id") is not None else "Unknown", "count": s["count"]} for s in popular_searches]

    # 4. Recent Pipeline Runs
    runs_cursor = await db.pipeline_runs.find().sort("start_time", -1).limit(5).to_list(length=5)
    recent_runs = []
    for r in runs_cursor:
        r["_id"] = str(r["_id"])
        # ensure no nested ObjectIds are left
        if "triggeredBy" in r and r["triggeredBy"]:
            r["triggeredBy"] = str(r["triggeredBy"])
        if "id" not in r:
            r["id"] = r["_id"]
        recent_runs.append(r)

    # 5. AI Usage Aggregation
    ai_usage_pipeline = [
        {"$group": {
            "_id": "$model",
            "tokens": {"$sum": "$total_tokens"},
            "cost": {"$sum": "$cost_estimate"}
        }}
    ]
    ai_entries = await db.ai_usage_logs.aggregate(ai_usage_pipeline).to_list(length=20)
    total_tokens = sum(e["tokens"] for e in ai_entries)
    total_cost = sum(e["cost"] for e in ai_entries)
    model_breakdown = {str(e["_id"]) if e.get("_id") is not None else "Unknown": {"tokens": e["tokens"], "cost": e["cost"]} for e in ai_entries}

    def strip_oids(obj):
        if type(obj).__name__ == "ObjectId":
            return str(obj)
        if isinstance(obj, list):
            return [strip_oids(v) for v in obj]
        elif isinstance(obj, dict):
            new_dict = {}
            for k, v in obj.items():
                if k == "_id":
                    new_dict[k] = str(v)
                elif hasattr(v, "inserted_id"):
                    continue
                else:
                    new_dict[k] = strip_oids(v)
            return new_dict
        return obj

    raw_response = {
        "total_views": total_views,
        "top_places": top_places,
        "popular_searches": popular_searches,
        "recent_runs": recent_runs,
        "ai_usage": {
            "total_tokens": total_tokens,
            "total_cost": total_cost,
            "model_breakdown": model_breakdown
        }
    }
    return strip_oids(raw_response)

@router.post("/stop-pipeline/{run_id}")
async def stop_pipeline(run_id: str, user=Depends(get_current_user)):
    """Kill switch to stop a running pipeline."""
    if user.get("role") != "admin" and user.get("tier") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required.")
    
    db = await get_mongo_db()
    result = await db.pipeline_runs.update_one(
        {"id": run_id, "status": "running"},
        {"$set": {"stop_requested": True, "status": "stopping"}}
    )
    if result.modified_count == 0:
        return {"message": "Pipeline not running or already stopped."}
    return {"message": "Stop request sent to pipeline."}

@router.get("/stats")
async def get_admin_stats(user=Depends(get_current_user)):
    """Alias for dashboard stats."""
    return await get_analytics_overview(user)

@router.post("/analytics/track")
@limiter.limit("30/minute")
async def track_telemetry(request: Request, place_id: Optional[str] = None, type: str = "view", search_term: Optional[str] = None, session_id: Optional[str] = None):
    """Endpoint for frontend to report user activity to MongoDB."""
    db = await get_mongo_db()
    import uuid
    await db.visitor_analytics.insert_one({
        "id": str(uuid.uuid4()),
        "place_id": place_id,
        "type": type,
        "search_term": search_term,
        "timestamp": datetime.now(),
        "session_id": session_id
    })
    return {"status": "tracked"}

@router.get("/system/backups")
async def list_system_backups(user=Depends(get_current_user)):
    """List all available backup folders."""
    if user.get("role") != "admin" and user.get("tier") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required.")
    
    # Define BACKUP_ROOT relative to the backend directory
    # Updated to handle potential directory structure variations
    BACKUP_ROOT = Path(os.getcwd()) / "backups"
    
    backups = []
    if BACKUP_ROOT.exists():
        dirs = [d for d in BACKUP_ROOT.iterdir() if d.is_dir()]
        # Sort by creation time (descending)
        dirs.sort(key=lambda x: x.stat().st_mtime, reverse=True)
        
        for d in dirs:
            # Get list of files in the backup folder
            files = [f.name for f in d.iterdir() if f.is_file()]
            backups.append({
                "folder": d.name,
                "created": datetime.fromtimestamp(d.stat().st_mtime).isoformat(),
                "files": files
            })
    return {"backups": backups}

@router.post("/system/backup")
async def trigger_system_backup(user=Depends(get_current_user)):
    """Trigger a new system-wide backup."""
    if user.get("role") != "admin" and user.get("tier") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required.")
    
    guard = SystemGuard()
    backup_name = await guard.backup()
    return {"message": "Backup completed successfully", "folder": backup_name}

@router.post("/system/restore")
async def trigger_system_restore(payload: dict, user=Depends(get_current_user)):
    """Restore system to a specific backup point."""
    if user.get("role") != "admin" and user.get("tier") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required.")
    
    folder = payload.get("folder")
    if not folder:
        raise HTTPException(status_code=400, detail="Folder name is required.")
        
    guard = SystemGuard()
    success = await guard.restore(folder, skip_confirm=True)
    if success:
        return {"message": f"System restored to {folder} successfully."}
    else:
        raise HTTPException(status_code=500, detail="Restoration failed. Check server logs.")
