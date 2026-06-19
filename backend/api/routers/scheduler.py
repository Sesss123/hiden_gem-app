# backend/api/routes_scheduler.py
# Job Scheduler REST API — CRUD + run-now + logs

from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, Literal
from datetime import datetime

from core.scheduler import tripme_scheduler

router = APIRouter(prefix="/api/scheduler", tags=["scheduler"])


# ─── MODELS ──────────────────────────────────────────────────────────────────
class CreateJobRequest(BaseModel):
    name: str
    job_type: Literal["pipeline_full", "cache_clear", "key_status_log"] = "pipeline_full"
    description: Optional[str] = ""
    schedule_type: Literal["interval", "cron"] = "interval"
    interval_value: Optional[int] = 6
    interval_unit: Optional[Literal["minutes", "hours", "days"]] = "hours"
    cron: Optional[str] = "0 2 * * *"   # only used if schedule_type == "cron"

class UpdateJobRequest(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    schedule_type: Optional[Literal["interval", "cron"]] = None
    interval_value: Optional[int] = None
    interval_unit: Optional[Literal["minutes", "hours", "days"]] = None
    cron: Optional[str] = None


# ─── LIST JOBS ────────────────────────────────────────────────────────────────
@router.get("/jobs")
async def list_jobs():
    jobs = tripme_scheduler.list_jobs()
    return JSONResponse({
        "success": True,
        "jobs": jobs,
        "total": len(jobs),
        "status": tripme_scheduler.get_status(),
        "timestamp": datetime.utcnow().isoformat() + "Z"
    })


# ─── ADD JOB ─────────────────────────────────────────────────────────────────
@router.post("/jobs")
async def create_job(request: CreateJobRequest):
    if not request.name.strip():
        raise HTTPException(status_code=400, detail="Job name is required.")

    job = tripme_scheduler.add_job(
        name=request.name,
        job_type=request.job_type,
        schedule_type=request.schedule_type,
        interval_value=request.interval_value or 6,
        interval_unit=request.interval_unit or "hours",
        cron=request.cron or "0 2 * * *",
        description=request.description or "",
    )
    return JSONResponse({"success": True, "job": job}, status_code=201)


# ─── UPDATE JOB ──────────────────────────────────────────────────────────────
@router.put("/jobs/{job_id}")
async def update_job(job_id: str, request: UpdateJobRequest):
    result = tripme_scheduler.update_job(
        job_id=job_id,
        name=request.name,
        description=request.description,
        schedule_type=request.schedule_type,
        interval_value=request.interval_value,
        interval_unit=request.interval_unit,
        cron=request.cron
    )
    if not result.get("success"):
        raise HTTPException(status_code=404, detail=result.get("error", "Job not found"))
    return JSONResponse(result)


# ─── TOGGLE (enable/disable) ──────────────────────────────────────────────────
@router.post("/jobs/{job_id}/toggle")
async def toggle_job(job_id: str):
    result = tripme_scheduler.toggle_job(job_id)
    if not result.get("success"):
        raise HTTPException(status_code=404, detail=result.get("error", "Job not found"))
    return JSONResponse(result)


# ─── RUN NOW ─────────────────────────────────────────────────────────────────
@router.post("/jobs/{job_id}/run-now")
async def run_job_now(job_id: str):
    result = tripme_scheduler.run_now(job_id)
    if not result.get("success"):
        raise HTTPException(status_code=404, detail=result.get("error", "Job not found"))
    return JSONResponse(result)


# ─── DELETE JOB ──────────────────────────────────────────────────────────────
@router.delete("/jobs/{job_id}")
async def delete_job(job_id: str):
    result = tripme_scheduler.delete_job(job_id)
    if not result.get("success"):
        raise HTTPException(status_code=404, detail=result.get("error", "Job not found"))
    return JSONResponse(result)


# ─── RUN LOGS ─────────────────────────────────────────────────────────────────
@router.get("/logs")
async def get_run_logs(limit: int = 50):
    logs = tripme_scheduler.get_run_logs(limit=min(limit, 100))
    return JSONResponse({
        "success": True,
        "logs": logs,
        "total": len(logs),
    })


# ─── SCHEDULER STATUS ─────────────────────────────────────────────────────────
@router.get("/status")
async def get_scheduler_status():
    return JSONResponse({
        "success": True,
        **tripme_scheduler.get_status(),
        "timestamp": datetime.utcnow().isoformat() + "Z"
    })
