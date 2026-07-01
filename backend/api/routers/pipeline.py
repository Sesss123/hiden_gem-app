# backend/api/routes_pipeline.py
# UPGRADED: New status, vision-analyze, cache-status endpoints + alert status

from fastapi import APIRouter, BackgroundTasks, Request, HTTPException, Header, Depends
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import logging
import os

from pipeline.logger import read_log_file, get_log_summary
from pipeline.alert_manager import get_alert_manager
# from core.key_rotator import multi_key_rotator (Moved to lazy getter)
# Deferring heavy AI imports to lazy getters
from pipeline.scheduler import global_scheduler as scheduler
from core import config
from core.mongodb import get_mongo_db
from core.security import get_current_user, verify_internal_key

router = APIRouter(prefix="/api/pipeline", tags=["pipeline"])
logger = logging.getLogger("PipelineAPI")

# Lazy initializers for AI engines
_discovery_engine = None
_extractor_instance = None

def get_discovery_engine():
    global _discovery_engine
    if _discovery_engine is None:
        from pipeline.discovery import AIDiscovery
        _discovery_engine = AIDiscovery()
    return _discovery_engine

def get_extractor_instance():
    global _extractor_instance
    if _extractor_instance is None:
        try:
            from pipeline.ai_extractor import AIExtractor
            _extractor_instance = AIExtractor()
        except Exception:
            _extractor_instance = None
    return _extractor_instance

def get_key_rotator():
    from core.key_rotator import multi_key_rotator
    return multi_key_rotator

# ─── Runtime state for live monitoring ────────────────────────────────────────
_pipeline_state = {
    "status": "idle",       # idle | running | completed | failed
    "started_at": None,
    "completed_at": None,
    "current_step": None,
    "steps_completed": 0,
    "total_steps": 7,
    "last_result": None,
    "last_error": None,
    "active_workers": {},
    "agent_monologue": [],  # New: Internal monologue for ReAct agent
    "alert_status": {},
    "tank_hive": {
        "status": "idle",
        "total_found": 0,
        "rejected_noise": 0,
        "current_district": None,
        "current_category": None,
        "districts_completed": []
    }
}

def get_pipeline_state():
    return _pipeline_state.copy()

def set_pipeline_state(**kwargs):
    global _pipeline_state
    _pipeline_state.update(kwargs)

class PipelineStatusUpdate(BaseModel):
    status: str
    current_step: Optional[str] = None
    steps_completed: Optional[int] = 0
    total_steps: Optional[int] = 7
    last_error: Optional[str] = None
    score: Optional[float] = None
    worker_info: Optional[dict] = None # {url, step, cache_hit}

@router.post("/update-status")
async def update_pipeline_status(data: PipelineStatusUpdate, authorized: bool = Depends(verify_internal_key)):
    """Internal bridge to update live UI from external scripts."""
    
    update_data = {
        "status": data.status,
        "current_step": data.current_step,
        "steps_completed": data.steps_completed,
        "total_steps": data.total_steps,
        "last_error": data.last_error,
        "score": data.score
    }
    
    if data.status == "running" and not _pipeline_state.get("started_at"):
        update_data["started_at"] = datetime.utcnow().isoformat()
    if data.status == "completed":
        update_data["completed_at"] = datetime.utcnow().isoformat()
        update_data["active_workers"] = {}

    if data.worker_info:
        url = data.worker_info.get("url")
        if url:
             if data.status == "running":
                 _pipeline_state["active_workers"][url] = {
                     "step": data.worker_info.get("step"),
                     "cache_hit": data.worker_info.get("cache_hit", False),
                     "timestamp": datetime.utcnow().isoformat()
                 }
             elif data.status in ["completed", "failed"]:
                 if url in _pipeline_state["active_workers"]:
                     del _pipeline_state["active_workers"][url]

    set_pipeline_state(**{k: v for k, v in update_data.items() if v is not None})
    return {"success": True}

# ─── CORE PIPELINE ENDPOINTS ──────────────────────────────────────────────────

@router.get("/stats")
async def get_pipeline_stats(user=Depends(get_current_user)):
    """Returns MongoDB telemetry for the dashboard."""
    db = await get_mongo_db()
    stats = {}
    try:
        stats['approved'] = await db.places.count_documents({"status": "approved"})
        stats['pending'] = await db.places.count_documents({"status": "pending"})
        stats['rejected'] = await db.places.count_documents({"status": "rejected"})
        
        last_item = await db.places.find_one(sort=[("created_at", -1)])
        stats['last_run'] = last_item["created_at"].isoformat() if last_item else "Never"
    except Exception as e:
        logger.error(f"Stats error: {e}")
        return {"error": str(e)}
    return stats

@router.get("/logs")
async def get_pipeline_logs(user=Depends(get_current_user)):
    """Returns recent harvest activities from MongoDB."""
    db = await get_mongo_db()
    try:
        cursor = db.places.find({}, {"name": 1, "status": 1, "created_at": 1, "data_source": 1}).sort("created_at", -1).limit(10)
        logs = []
        async for doc in cursor:
            doc["_id"] = str(doc["_id"])
            if "created_at" in doc: doc["created_at"] = doc["created_at"].isoformat()
            logs.append(doc)
        return logs
    except Exception as e:
        logger.error(f"Logs error: {e}")
        return []

@router.post("/trigger")
async def trigger_pipeline(request: Request, user=Depends(get_current_user)):
    """Manually triggers the pipeline via global scheduler."""
    internal_key = request.headers.get("X-Admin-Internal-Key")
    is_internal = internal_key and (internal_key == config.INTERNAL_BRIDGE_KEY)

    if not is_internal and user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin privileges required.")

    target_urls = ["https://www.sltda.gov.lk/en/tourist-attractions"]
    
    scheduler.start() # Ensure it's running
    job_id = scheduler.add_adhoc_job(target_urls, name="Dashboard Manual Trigger")
    
    return {"message": "Pipeline job queued.", "job_id": job_id, "status": "running"}

@router.get("/runs")
async def get_pipeline_runs(user=Depends(get_current_user)):
    """Returns historic pipeline runs."""
    db = await get_mongo_db()
    cursor = db.pipeline_runs.find().sort("start_time", -1).limit(20)
    runs = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        if "start_time" in doc: doc["start_time"] = doc["start_time"].isoformat()
        if "end_time" in doc: doc["end_time"] = doc["end_time"].isoformat()
        runs.append(doc)
    return runs

class DiscoveryRequest(BaseModel):
    prompt: str

@router.post("/discover")
async def discover_new_places(
    request: DiscoveryRequest, 
    background_tasks: BackgroundTasks, 
    user=Depends(get_current_user)
):
    """AI-driven discovery based on a natural language prompt."""
    if not user.get("is_authenticated") or (user.get("role") != "admin" and user.get("tier") != "admin"):
        raise HTTPException(status_code=403, detail="Admin privileges required for AI Discovery.")

    set_pipeline_state(
        status="running",
        started_at=datetime.utcnow().isoformat(),
        completed_at=None,
        current_step="Agent: Initializing Thought Process",
        steps_completed=0,
        agent_monologue=[]
    )

    from pipeline.agent_orchestrator import agent_orchestrator
    background_tasks.add_task(agent_orchestrator.execute_directive, request.prompt)
    
    return {
        "success": True, 
        "message": "Neural Command received. Agent is thinking.",
        "prompt": request.prompt
    }

@router.post("/discover-district")
async def discover_district_route(request: Request, bg_tasks: BackgroundTasks, authorized: bool = Depends(verify_internal_key)):
    """
    Trigger a deep discovery for a specific district.
    """
    
    body = await request.json()
    district = body.get("district")
    
    if not district:
        raise HTTPException(status_code=400, detail="District name required")

    from pipeline.district_discovery import DistrictDiscoveryAgent
    agent = DistrictDiscoveryAgent()
    bg_tasks.add_task(agent.discover_district, district)
    
    return {
        "success": True,
        "message": f"Deep Discovery started for {district} district.",
        "estimated_jobs": 15
    }

@router.post("/stop")
async def stop_discovery(authorized: bool = Depends(verify_internal_key)):
    from pipeline.agent_orchestrator import agent_orchestrator
    
    agent_orchestrator.stop_requested = True
    return {"success": True, "message": "Stop signal broadcasted to Neural Agent."}

@router.post("/tank-hive")
async def trigger_tank_hive(background_tasks: BackgroundTasks, user=Depends(get_current_user)):
    """Triggers the district-wise Smart Tank Discovery Hive."""
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin privileges required.")

    set_pipeline_state(
        status="running",
        current_step="Hive Discovery: Brainstorming Sri Lankan Tanks",
        tank_hive={
            "status": "running",
            "total_found": 0,
            "rejected_noise": 0,
            "current_district": "Initializing",
            "districts_completed": []
        }
    )

    from discovery.universal_discovery_hive import UniversalDiscoveryHive
    hive = UniversalDiscoveryHive()
    
    async def run_and_track():
        # UniversalHive uses 'run_master_hive' or 'run_hive'
        # We'll adapt the telemetry tracking if available
        await hive.run_master_hive()
        set_pipeline_state(status="completed")

    background_tasks.add_task(run_and_track)
    
    return {"success": True, "message": "Smart Tank Hive discovery started."}

# ─── LIVE PIPELINE STATUS ─────────────────────────────────────────────────────
@router.post("/universal-hive")
async def start_universal_hive(background_tasks: BackgroundTasks, authorized: bool = Depends(verify_internal_key)):
    """Triggers the Sri Lanka Master Plan — Universal Category Discovery."""

    from discovery.universal_discovery_hive import UniversalDiscoveryHive
    hive = UniversalDiscoveryHive()
    
    background_tasks.add_task(hive.run_master_hive)
    
    return {
        "status": "triggered",
        "message": "Universal Discovery Hive unleashed across all districts and categories."
    }

@router.get("/status")
async def get_live_pipeline_status(user=Depends(get_current_user)):
    """Returns real-time pipeline health and recent logs for the UI console."""
    today_logs = read_log_file()
    summary = get_log_summary(today_logs)

    total_ops = sum(summary.values())
    pass_rate = round((summary.get("INFO", 0) / max(total_ops, 1) * 100), 1)
    health_score = round(max(0, 100 - (summary.get("ERROR", 0) / max(total_ops, 1) * 100)), 1)
    
    # Get last 5 relevant logs for the console
    recent_entries = [f"[{e['timestamp'][11:19]}] {e['message']}" for e in today_logs[-8:]]

    return {
        "status": _pipeline_state["status"],
        "started_at": _pipeline_state.get("started_at"),
        "completed_at": _pipeline_state.get("completed_at"),
        "current_step": _pipeline_state.get("current_step", "Idle"),
        "steps_completed": _pipeline_state.get("steps_completed", 0),
        "total_steps": _pipeline_state.get("total_steps", 7),
        "health_score": health_score,
        "validation_pass_rate": pass_rate,
        "log_summary": summary,
        "last_logs": recent_entries,
        "last_error": _pipeline_state.get("last_error"),
        "alert_status": get_alert_manager().get_status(),
        "active_workers": _pipeline_state["active_workers"],
        "agent_monologue": _pipeline_state.get("agent_monologue", []),
        "tank_hive_stats": _pipeline_state.get("tank_hive"),
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }

class SmartIntakeRequest(BaseModel):
    url: str

@router.post("/smart-intake")
async def process_smart_intake(request: SmartIntakeRequest, req: Request, user=Depends(get_current_user)):
    """Single URL high-fidelity intake."""
    internal_key = req.headers.get("X-Admin-Internal-Key")
    is_internal = internal_key and (internal_key == config.INTERNAL_BRIDGE_KEY)

    if not is_internal and user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin privileges required.")

    logger.info(f"[PipelineAPI] Smart Intake triggered for: {request.url}")
    
    from pipeline.smart_intake_service import smart_intake_service
    result = await smart_intake_service.process_url(request.url)
    
    if not result:
        return JSONResponse({
            "success": False,
            "message": "Extraction failed. The URL might be blocked or content too sparse."
        }, status_code=500)

    return JSONResponse({
        "success": True,
        "data": result,
        "processed_at": datetime.utcnow().isoformat() + "Z"
    })

# ─── VISION AI ANALYSIS ───────────────────────────────────────────────────────
class VisionAnalysisRequest(BaseModel):
    image_url: str
    place_name: Optional[str] = None

@router.post("/vision-analyze")
async def analyze_image_vision(request: VisionAnalysisRequest, user=Depends(get_current_user)):
    """Use Gemini Vision AI to detect facility features."""
    extractor = get_extractor_instance()
    if not extractor:
        raise HTTPException(status_code=503, detail="AI Extractor not initialized.")
    
    if not request.image_url:
        raise HTTPException(status_code=400, detail="Image URL is required.")

    result = await extractor.analyze_image_features(request.image_url, request.place_name)
    if result is None:
        return JSONResponse({
            "success": False,
            "message": "Vision AI analysis failed or unavailable.",
            "features": None
        }, status_code=500)

    return JSONResponse({
        "success": True,
        "image_url": request.image_url,
        "place_name": request.place_name,
        "features": result,
        "cache_hit": result.get("_cached", False),
        "analyzed_at": datetime.utcnow().isoformat() + "Z"
    })

# ─── CACHE STATUS ─────────────────────────────────────────────────────────────
@router.get("/cache-status")
async def get_cache_status(user=Depends(get_current_user)):
    """Returns current scraping cache statistics."""
    from pathlib import Path
    import json
    cache_dir = Path("data/cache")
    if not cache_dir.exists():
        return {"total_entries": 0, "total_size_mb": 0, "entries": []}
    html_files = sorted(cache_dir.glob("*.html"), key=lambda f: f.stat().st_mtime, reverse=True)
    total_size = sum(f.stat().st_size for f in html_files)
    entries = []
    for html_f in html_files[:10]:
        meta_f = cache_dir / (html_f.stem + ".meta.json")
        meta = {}
        if meta_f.exists():
            try:
                with open(meta_f, "r") as f:
                    meta = json.load(f)
            except Exception: pass
        entries.append({
            "key": html_f.stem,
            "url": meta.get("url", "unknown"),
            "cached_at": meta.get("cached_at"),
            "size_kb": round(html_f.stat().st_size / 1024, 1)
        })
    return {
        "total_entries": len(html_files),
        "total_size_mb": round(total_size / 1024 / 1024, 2),
        "entries": entries
    }

# ─── API KEY MANAGEMENT ───────────────────────────────────────────────────────
@router.get("/keys")
async def list_api_keys(authorized: bool = Depends(verify_internal_key)):
    """List all registered API keys across all providers."""
    status = get_key_rotator().get_status()
    return JSONResponse({
        "success": True,
        "keys": status["keys"],
        "total": status["total_keys"],
        "providers": status["providers"],
        "timestamp": datetime.utcnow().isoformat() + "Z"
    })

class AddKeyRequest(BaseModel):
    api_key: str
    provider: str = "google"
    nickname: Optional[str] = ""

@router.post("/keys")
async def add_api_key(request: AddKeyRequest, authorized: bool = Depends(verify_internal_key)):
    result = get_key_rotator().add_key(request.api_key, request.provider, request.nickname or "")
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["error"])
    return JSONResponse({"success": True, **result})

@router.delete("/keys/{index}")
async def remove_api_key(index: int, authorized: bool = Depends(verify_internal_key)):
    result = get_key_rotator().remove_key(index)
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["error"])
    return JSONResponse({"success": True, **result})
