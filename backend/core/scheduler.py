# backend/core/scheduler.py
# TripMeAI Job Scheduler
# Manages automated pipeline jobs using APScheduler.
# Jobs are persisted to data/scheduler_jobs.json — survive restarts.
#
# Job types supported:
#   - pipeline_full   : Run the full AI harvesting pipeline
#   - pipeline_custom : Run pipeline with custom source list
#   - cache_clear     : Clear the 24hr HTML cache
#   - key_reset_check : Log and alert on key rotation status

import json
import logging
import asyncio
from datetime import datetime, date
from typing import Optional, Dict, Any, List
from pathlib import Path
from threading import Lock

logger = logging.getLogger("JobScheduler")

JOBS_FILE = Path("data/scheduler_jobs.json")

# ─── Try to import APScheduler (optional dependency) ──────────────────────────
try:
    from apscheduler.schedulers.asyncio import AsyncIOScheduler
    from apscheduler.triggers.cron import CronTrigger
    from apscheduler.triggers.interval import IntervalTrigger
    APSCHEDULER_AVAILABLE = True
except ImportError:
    APSCHEDULER_AVAILABLE = False
    logger.warning("[Scheduler] APScheduler not installed. Run: pip install apscheduler")


# ─── Job Definition ────────────────────────────────────────────────────────────
DEFAULT_JOBS = []  # No pre-created jobs — user creates via dashboard


# ─────────────────────────────────────────────────────────────────────────────
class TripMeScheduler:
    """
    Manages scheduled jobs for the TripMeAI pipeline.

    Jobs are stored in data/scheduler_jobs.json.
    Job schedules use cron expressions or interval-based triggers.
    """

    def __init__(self):
        self._lock = Lock()
        self._scheduler = None
        self._jobs_config: list[dict] = []
        self._run_log: list[dict] = []   # last 50 execution events
        self._load_jobs()

        if APSCHEDULER_AVAILABLE:
            self._scheduler = AsyncIOScheduler(timezone="UTC")
            self._register_all()
            logger.info("[Scheduler] ✅ APScheduler initialized.")
        else:
            logger.warning("[Scheduler] Running without APScheduler — jobs won't auto-execute.")

    # ─── Persistence ─────────────────────────────────────────────────────────
    def _load_jobs(self):
        """Load jobs from JSON config file."""
        JOBS_FILE.parent.mkdir(parents=True, exist_ok=True)
        if not JOBS_FILE.exists():
            self._jobs_config = []
            return
        try:
            with open(JOBS_FILE, "r") as f:
                data = json.load(f)
            self._jobs_config = data.get("jobs", [])
            logger.info(f"[Scheduler] Loaded {len(self._jobs_config)} job(s) from config.")
        except Exception as e:
            logger.warning(f"[Scheduler] Could not load jobs file: {e}")
            self._jobs_config = []

    def _save_jobs(self):
        """Persist job config to JSON file."""
        try:
            JOBS_FILE.parent.mkdir(parents=True, exist_ok=True)
            with open(JOBS_FILE, "w") as f:
                json.dump({
                    "jobs": self._jobs_config,
                    "updated_at": datetime.utcnow().isoformat()
                }, f, indent=2)
        except Exception as e:
            logger.warning(f"[Scheduler] Could not save jobs: {e}")

    # ─── APScheduler Registration ─────────────────────────────────────────────
    def _register_all(self):
        """Register all enabled jobs with APScheduler."""
        if not self._scheduler:
            return
        for job in self._jobs_config:
            if job.get("enabled", True):
                self._register_job(job)

    def _register_job(self, job: dict):
        """Register a single job with APScheduler."""
        if not self._scheduler:
            return
        jid = job["id"]
        schedule_type = job.get("schedule_type", "interval")

        try:
            if schedule_type == "cron":
                trigger = CronTrigger.from_crontab(job["cron"])
            else:
                unit = job.get("interval_unit", "hours")
                value = int(job.get("interval_value", 6))
                trigger = IntervalTrigger(**{unit: value})

            # Remove existing if re-registering
            try:
                self._scheduler.remove_job(jid)
            except Exception:
                pass

            self._scheduler.add_job(
                self._execute_job,
                trigger=trigger,
                id=jid,
                args=[jid],
                replace_existing=True,
                name=job.get("name", jid),
                misfire_grace_time=300
            )
            logger.info(f"[Scheduler] ⏰ Registered job: {job.get('name')} ({jid})")
        except Exception as e:
            logger.error(f"[Scheduler] Failed to register job {jid}: {e}")

    def _unregister_job(self, job_id: str):
        """Remove a job from APScheduler."""
        if not self._scheduler:
            return
        try:
            self._scheduler.remove_job(job_id)
            logger.info(f"[Scheduler] Unregistered job: {job_id}")
        except Exception:
            pass

    # ─── Job Execution ────────────────────────────────────────────────────────
    async def _execute_job(self, job_id: str):
        """Execute a job by its ID. Called by APScheduler."""
        job = self._find_job(job_id)
        if not job:
            logger.warning(f"[Scheduler] Job not found for execution: {job_id}")
            return

        job_type = job.get("job_type", "pipeline_full")
        job_name = job.get("name", job_id)
        started_at = datetime.utcnow()

        logger.info(f"[Scheduler] 🚀 Executing job: {job_name} ({job_type})")
        self._log_run(job_id, job_name, "running", started_at)

        # Update last_run in config
        with self._lock:
            for j in self._jobs_config:
                if j["id"] == job_id:
                    j["last_run"] = started_at.isoformat()
                    j["run_count"] = j.get("run_count", 0) + 1
                    break
            self._save_jobs()

        try:
            if job_type == "pipeline_full":
                from pipeline.main_pipeline import run_pipeline
                result = await run_pipeline()
                status = "success"
                detail = f"{result.get('success', 0)} succeeded, {result.get('failed', 0)} failed in {result.get('duration_seconds', 0):.1f}s"

            elif job_type == "cache_clear":
                from pathlib import Path
                import shutil
                cache_dir = Path("data/cache")
                count = len(list(cache_dir.glob("*.html"))) if cache_dir.exists() else 0
                if cache_dir.exists():
                    shutil.rmtree(cache_dir)
                    cache_dir.mkdir(parents=True, exist_ok=True)
                status = "success"
                detail = f"Cleared {count} cache entries"

            elif job_type == "key_status_log":
                from core.key_rotator import gemini_key_rotator
                s = gemini_key_rotator.get_status()
                status = "success"
                detail = f"{s['total_keys']} keys, {s['total_remaining_queries']} queries remaining today"

            else:
                status = "skipped"
                detail = f"Unknown job type: {job_type}"

        except Exception as e:
            status = "error"
            detail = str(e)
            logger.error(f"[Scheduler] ❌ Job {job_name} failed: {e}")

        finished_at = datetime.utcnow()
        elapsed = (finished_at - started_at).total_seconds()
        self._log_run(job_id, job_name, status, started_at, finished_at, detail, elapsed)

        # Update last_status
        with self._lock:
            for j in self._jobs_config:
                if j["id"] == job_id:
                    j["last_status"] = status
                    j["last_run_detail"] = detail
                    break
            self._save_jobs()

        logger.info(f"[Scheduler] ✅ Job {job_name} → {status} ({elapsed:.1f}s): {detail}")

    def _log_run(self, job_id, job_name, status, started_at, finished_at=None, detail="", elapsed=0):
        entry = {
            "job_id": job_id,
            "job_name": job_name,
            "status": status,
            "started_at": started_at.isoformat(),
            "finished_at": finished_at.isoformat() if finished_at else None,
            "duration_seconds": round(elapsed, 1),
            "detail": detail,
        }
        self._run_log.insert(0, entry)
        self._run_log = self._run_log[:100]  # Keep last 100

    # ─── CRUD ─────────────────────────────────────────────────────────────────
    def _find_job(self, job_id: str) -> dict | None:
        return next((j for j in self._jobs_config if j["id"] == job_id), None)

    def list_jobs(self) -> list[dict]:
        """Return all jobs with next_run time from APScheduler."""
        with self._lock:
            result = []
            for job in self._jobs_config:
                info = dict(job)
                if self._scheduler:
                    try:
                        aps_job = self._scheduler.get_job(job["id"])
                        if aps_job and aps_job.next_run_time:
                            info["next_run"] = aps_job.next_run_time.isoformat()
                        else:
                            info["next_run"] = None
                    except Exception:
                        info["next_run"] = None
                result.append(info)
            return result

    def add_job(self, name: str, job_type: str, schedule_type: str,
                interval_value: int = 6, interval_unit: str = "hours",
                cron: str = "0 2 * * *", description: str = "") -> dict:
        """Create and register a new job."""
        import uuid
        with self._lock:
            job_id = f"job_{uuid.uuid4().hex[:8]}"
            job = {
                "id": job_id,
                "name": name,
                "job_type": job_type,
                "description": description,
                "schedule_type": schedule_type,   # "interval" | "cron"
                "interval_value": interval_value,
                "interval_unit": interval_unit,   # minutes | hours | days
                "cron": cron,
                "enabled": True,
                "created_at": datetime.utcnow().isoformat(),
                "last_run": None,
                "last_status": None,
                "run_count": 0,
            }
            self._jobs_config.append(job)
            self._save_jobs()

        if self._scheduler and not self._scheduler.running:
            self._scheduler.start()

        self._register_job(job)
        return job

    def update_job(self, job_id: str, name: Optional[str] = None, 
                   description: Optional[str] = None,
                   schedule_type: Optional[str] = None,
                   interval_value: Optional[int] = None,
                   interval_unit: Optional[str] = None,
                   cron: Optional[str] = None) -> dict:
        """Update an existing job and re-register it."""
        with self._lock:
            job = self._find_job(job_id)
            if not job:
                return {"success": False, "error": "Job not found"}

            if name is not None: job["name"] = name
            if description is not None: job["description"] = description
            if schedule_type is not None: job["schedule_type"] = schedule_type
            if interval_value is not None: job["interval_value"] = interval_value
            if interval_unit is not None: job["interval_unit"] = interval_unit
            if cron is not None: job["cron"] = cron

            self._save_jobs()

        # Re-register if enabled
        if job.get("enabled", True):
            self._register_job(job)
        
        return {"success": True, "job": job}

    def toggle_job(self, job_id: str) -> dict:
        """Enable/disable a job."""
        with self._lock:
            job = self._find_job(job_id)
            if not job:
                return {"success": False, "error": "Job not found"}
            job["enabled"] = not job.get("enabled", True)
            self._save_jobs()

        if job["enabled"]:
            self._register_job(job)
        else:
            self._unregister_job(job_id)

        return {"success": True, "enabled": job["enabled"]}

    def delete_job(self, job_id: str) -> dict:
        """Delete a job permanently."""
        with self._lock:
            job = self._find_job(job_id)
            if not job:
                return {"success": False, "error": "Job not found"}
            self._jobs_config = [j for j in self._jobs_config if j["id"] != job_id]
            self._save_jobs()

        self._unregister_job(job_id)
        return {"success": True}

    def run_now(self, job_id: str) -> dict:
        """Trigger a job to run immediately (async fire-and-forget)."""
        job = self._find_job(job_id)
        if not job:
            return {"success": False, "error": "Job not found"}
        try:
            loop = asyncio.get_event_loop()
            loop.create_task(self._execute_job(job_id))
        except RuntimeError:
            asyncio.run(self._execute_job(job_id))
        return {"success": True, "message": f"Job '{job['name']}' triggered."}

    def get_run_logs(self, limit: int = 50) -> list[dict]:
        """Return recent job execution logs."""
        return self._run_log[:limit]

    def get_status(self) -> dict:
        """Scheduler-level health summary."""
        total = len(self._jobs_config)
        enabled = sum(1 for j in self._jobs_config if j.get("enabled"))
        running = self._scheduler.running if self._scheduler else False
        return {
            "scheduler_running": running,
            "apscheduler_available": APSCHEDULER_AVAILABLE,
            "total_jobs": total,
            "enabled_jobs": enabled,
            "paused_jobs": total - enabled,
            "recent_runs": len(self._run_log),
        }

    def start(self):
        """Start the APScheduler (call after FastAPI startup)."""
        if self._scheduler and not self._scheduler.running:
            self._scheduler.start()
            logger.info("[Scheduler] ▶️  APScheduler started.")

    def shutdown(self):
        """Shutdown APScheduler gracefully."""
        if self._scheduler and self._scheduler.running:
            self._scheduler.shutdown(wait=False)
            logger.info("[Scheduler] ⏹️  APScheduler shut down.")


# ── Global Singleton ──────────────────────────────────────────────────────────
tripme_scheduler = TripMeScheduler()
