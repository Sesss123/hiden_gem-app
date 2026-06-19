# backend/pipeline/scheduler.py

import asyncio
import logging
import os
import uuid
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from datetime import datetime

# Import our components
from .scraper import UniversalScraper
from .ai_extractor import AIExtractor
from .validator import DataValidator
from .integrity_guard import IntegrityGuard
from core.mongodb import get_mongo_db
from core import config

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("Scheduler")


class PipelineScheduler:
    def __init__(self):
        self._scheduler = None
        self._scraper = None
        self._extractor = None
        self._validator = None
        self._running_jobs = {}

    @property
    def scheduler(self):
        if self._scheduler is None:
            self._scheduler = AsyncIOScheduler()
        return self._scheduler

    @property
    def scraper(self):
        if self._scraper is None:
            self._scraper = UniversalScraper()
        return self._scraper

    @property
    def extractor(self):
        if self._extractor is None:
            self._extractor = AIExtractor()
        return self._extractor

    @property
    def validator(self):
        if self._validator is None:
            self._validator = DataValidator(threshold=75)
        return self._validator

    async def run_pipeline(self, target_urls: list, name: str = "Ad-hoc Discovery"):
        """Orchestrate the pipeline with parallel processing and kill-switch polling."""
        run_id = str(uuid.uuid4())
        start_time = datetime.now()
        logger.info(f"[Scheduler] Pipeline {run_id} ({name}) started with {len(target_urls)} URLs.")
        
        db = await get_mongo_db()
        
        run_record = {
            "id": run_id,
            "name": name,
            "start_time": start_time,
            "status": "running",
            "progress": 0,
            "stats": {"scraped": 0, "extracted": 0, "approved": 0, "rejected": 0},
            "stop_requested": False
        }
        await db.pipeline_runs.insert_one(run_record)

        # Semaphore to limit concurrency
        sem = asyncio.Semaphore(config.MAX_CONCURRENT_EXTRACTIONS)

        async def process_url(url, index):
            try:
                # 1. Check Kill Switch
                current_run = await db.pipeline_runs.find_one({"id": run_id})
                if current_run.get("stop_requested") or current_run.get("status") in ["stopping", "stopped"]:
                    logger.warning(f"[Scheduler] Run {run_id} Kill Switch triggered. Skipping {url}")
                    return

                async with sem:
                    logger.info(f"[Scheduler] Processing {url} ({index+1}/{len(target_urls)})")
                    
                    # Scrape
                    html = await self.scraper.get_dynamic(url)
                    if not html: return
                    await db.pipeline_runs.update_one({"id": run_id}, {"$inc": {"stats.scraped": 1}})
                    
                    # Extract (pass run_id for usage logging)
                    data = await self.extractor.extract_from_html(html, run_id=run_id)
                    if not data: return
                    await db.pipeline_runs.update_one({"id": run_id}, {"$inc": {"stats.extracted": 1}})
                    
                    # Validate
                    approved, score, details = await self.validator.validate_workflow_async(data)
                    stat_key = "stats.approved" if approved else "stats.rejected"
                    await db.pipeline_runs.update_one({"id": run_id}, {"$inc": {stat_key: 1}})
                    
                    # Store (Merge strategy logic)
                    await self.save_to_mongo(data, approved, score, url)
                    
            except Exception as e:
                logger.error(f"[Scheduler] Error processing {url}: {e}")

        try:
            # Run tasks in parallel
            tasks = [process_url(url, i) for i, url in enumerate(target_urls)]
            await asyncio.gather(*tasks)

            # Finalize
            await db.pipeline_runs.update_one(
                {"id": run_id},
                {
                    "$set": {
                        "status": "completed",
                        "end_time": datetime.now(),
                        "progress": 100
                    }
                }
            )
            logger.info(f"[Scheduler] Pipeline {run_id} finished.")

        except Exception as e:
            logger.error(f"[Scheduler] Pipeline crash: {e}")
            await db.pipeline_runs.update_one(
                {"id": run_id}, 
                {"$set": {"status": "failed", "last_error": str(e)}}
            )

    async def save_to_mongo(self, data: dict, approved: bool, score: int, source_url: str):
        db = await get_mongo_db()
        try:
            from slugify import slugify
            slug = slugify(data['name'])
            
            existing = await db.places.find_one({"slug": slug})
            
            # --- Strategy: Merge if exists ---
            data["slug"] = slug
            data["approved"] = 1 if approved else 0
            data["status"] = "approved" if approved else "pending"
            data["data_source"] = source_url
            data["score"] = score
            data["last_updated"] = datetime.now()
            
            # Logic to flag defective data for auto-repair
            is_defective = False
            if not data.get("district") or data.get("district") == "Not specified": is_defective = True
            if not data.get("category") or data.get("category") == "Not specified": is_defective = True
            if score < 60: is_defective = True
            
            data["is_defective"] = is_defective
            
            if existing:
                logger.info(f"[Scheduler] '{data['name']}' exists. Merging missing fields...")
                update_fields = {k: v for k, v in data.items() if k not in existing or not existing.get(k)}
                if update_fields:
                    await db.places.update_one({"slug": slug}, {"$set": update_fields})
            else:
                data["created_at"] = datetime.now()
                await db.places.insert_one(data)
                logger.info(f"[Scheduler] Saved new place '{data['name']}' to MongoDB.")
        except Exception as e:
            logger.error(f"[Scheduler] MongoDB Save Error: {e}")

    def add_adhoc_job(self, urls: list, name: str = "Manual Trigger"):
        """Adds a one-time job to the scheduler."""
        job_id = f"job_{uuid.uuid4().hex[:8]}"
        self.scheduler.add_job(
            self.run_pipeline, 
            'date', 
            run_date=datetime.now(), 
            args=[urls, name],
            id=job_id
        )
        return job_id

    def start(self):
        if not self.scheduler.running:
            self.scheduler.start()
            logger.info("Scheduler started.")
            
            # Add Maintenance Jobs
            self.scheduler.add_job(
                IntegrityGuard().run_clean_sweep,
                'interval',
                hours=6, # Run every 6 hours
                id='visual_integrity_sweep'
            )
            logger.info("[Scheduler] Registered recurring Visual Integrity Sweep.")

global_scheduler = PipelineScheduler()

if __name__ == "__main__":
    from core.mongodb import client
    sched = PipelineScheduler()
    sched.start()
    asyncio.run(sched.run_pipeline(["https://www.sltda.gov.lk/en/tourist-attractions"]))
