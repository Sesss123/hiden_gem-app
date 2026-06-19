# backend/pipeline/main_pipeline.py
# UPGRADED: Parallel scraping, MongoDB-centric, Vision Validated, Kill-Switch ready

import asyncio
import os
import json
import hashlib
import logging
from datetime import datetime, timedelta
from pathlib import Path

from pipeline.scraper import UniversalScraper
from pipeline.ai_extractor import AIExtractor
from pipeline.validator import DataValidator
from pipeline.vision_validator import vision_validator
from pipeline.enrichment_manager import enrichment_manager
from services.social_harvester import social_harvester
from pipeline.data_sources import get_source, SOURCES
from pipeline.logger import get_pipeline_logger
from pipeline.discovery import AIDiscovery
from pipeline.osm_discovery import osm_discovery
from pipeline.alert_manager import get_alert_manager
from core.mongodb import get_mongo_db
from core.key_rotator import multi_key_rotator
from core import config
from models.database_models import PipelineRun
import httpx
from slugify import slugify

logger = get_pipeline_logger("Pipeline")

RAW_DATA_DIR = Path("data/raw")
CACHE_DIR = Path("data/cache")
CACHE_TTL_HOURS = 24  # Don't re-scrape same URL for 24 hours

# ─── PARALLEL CONCURRENCY CONTROL ──────────────────────────────────────────────
MAX_CONCURRENT = config.MAX_CONCURRENT_EXTRACTIONS if hasattr(config, "MAX_CONCURRENT_EXTRACTIONS") else 5


# ─────────────────────────────────────────────────────────────────────────────
# CACHE HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def _cache_key(url: str) -> str:
    return hashlib.md5(url.encode()).hexdigest()[:12]


def _get_cached_html(url: str) -> str | None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    key = _cache_key(url)
    cache_file = CACHE_DIR / f"{key}.html"
    meta_file = CACHE_DIR / f"{key}.meta.json"

    if cache_file.exists() and meta_file.exists():
        try:
            with open(meta_file, "r") as f:
                meta = json.load(f)
            cached_at = datetime.fromisoformat(meta["cached_at"])
            if datetime.utcnow() - cached_at < timedelta(hours=CACHE_TTL_HOURS):
                logger.info(f"[Cache] ✅ HIT — Using cached HTML for: {url[:60]}")
                return cache_file.read_text(encoding="utf-8")
            else:
                logger.info(f"[Cache] ⏰ EXPIRED — Re-scraping: {url[:60]}")
        except Exception as e:
            logger.warning(f"[Cache] Read error: {e}")

    return None


def _save_to_cache(url: str, html: str):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    key = _cache_key(url)
    try:
        (CACHE_DIR / f"{key}.html").write_text(html, encoding="utf-8")
        with open(CACHE_DIR / f"{key}.meta.json", "w") as f:
            json.dump({"url": url, "cached_at": datetime.utcnow().isoformat()}, f)
        logger.info(f"[Cache] 💾 SAVED — {url[:60]}")
    except Exception as e:
        logger.warning(f"[Cache] Write error: {e}")


def _get_cache_stats() -> dict:
    if not CACHE_DIR.exists():
        return {"total_entries": 0, "total_size_mb": 0}
    html_files = list(CACHE_DIR.glob("*.html"))
    total_size = sum(f.stat().st_size for f in html_files)
    return {
        "total_entries": len(html_files),
        "total_size_mb": round(total_size / 1024 / 1024, 2)
    }


# ─────────────────────────────────────────────────────────────────────────────
# SINGLE SOURCE ORCHESTRATION
# ─────────────────────────────────────────────────────────────────────────────
async def orchestrate_item(key, source, scraper, extractor, validator, semaphore, run_id: str):
    """Handles the lifecycle of a single source with semaphore rate limiting."""
    async with semaphore:
        logger.info(f"[Pipeline] ⏩ Processing: {source['name']}")
        start_time = datetime.utcnow()

        # ── Phase 1: Cache Check ──
        html = _get_cached_html(source["url"])
        if not html:
            html = await scraper.scrape(source["url"], type=source.get("type", "static"))
            if not html:
                logger.error(f"[Pipeline] ❌ Scrape failed: {key}")
                get_alert_manager().record_failure(f"Scrape failed: {source['name']}")
                return False
            _save_to_cache(source["url"], html)
        else:
            logger.info(f"[Pipeline] Using cached HTML for {source['name']}")

        # Save raw HTML for audit
        RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)
        (RAW_DATA_DIR / f"{key.lower()}_raw.html").write_text(html, encoding="utf-8")

        # ── Phase 2: Dual AI Extraction ──
        extracted_data = await extractor.extract_from_html(html, run_id=run_id)
        if not extracted_data:
            logger.error(f"[Pipeline] ❌ AI Extraction failed: {key}")
            get_alert_manager().record_failure(f"Extraction failed: {source['name']}")
            return False

        get_alert_manager().record_success()

        # ── Phase 3: Visual Validation ──
        img_url = extracted_data.get("external_image_url")
        if img_url:
            v_res = await vision_validator.verify_location_match(
                img_url, 
                extracted_data.get("name"), 
                extracted_data.get("category")
            )
            # Core Validation
            extracted_data["_vision_validated"] = v_res.get("is_match", False)
            extracted_data["_vision_score"] = v_res.get("confidence", 0)
              # ── Phase 4: Modular Data Enrichment ──
        # 1. Source-Specific Transformation
        source_obj = get_source(key)
        if source_obj:
            extracted_data = source_obj.transform(extracted_data)
            logger.info(f"[Pipeline] Applied {key} specific transformations")

        # 2. Multi-Source Intelligence Orchestration (Maps + Wiki + OSM)
        extracted_data = await enrichment_manager.enrich_all(extracted_data)

        # 3. Social Trend Intelligence
        social_signals = await social_harvester.get_trend_signals(extracted_data['name'])
        extracted_data["social_signals"] = social_signals
        logger.info(f"✅ [Enrichment] Social Trend Signal: {social_signals['popularity_index']}% ({social_signals['top_platform']})")

        # ── Phase 5: Async Validation & Deduplication ──

        # ── Phase 5: Async Validation & Deduplication ──
        is_approved, score, val_details = await validator.validate_workflow_async(extracted_data)

        if val_details.get("is_duplicate"):
            logger.warning(f"[Pipeline] ⚠️ SKIPPING duplicate: {extracted_data.get('name')}")
            return True

        elapsed = (datetime.utcnow() - start_time).total_seconds()
        logger.info(f"[Pipeline] ✅ {extracted_data['name']} — Score: {score} | Approved: {is_approved} | {elapsed:.1f}s")

        return extracted_data


async def _genesis_batch_intake(items: list[dict], run_id: str):
    """Send processed records to Genesis in a single high-efficiency batch."""
    if not items: return
    
    try:
        genesis_url = os.getenv("GENESIS_ADMIN_URL", "http://localhost:3006")
        auth_key = os.getenv("PIPELINE_SECRET", config.INTERNAL_BRIDGE_KEY)
        
        # Prepare batch payload
        batch_items = []
        for itm in items:
            itm["run_id"] = run_id
            # Ensure required metadata is present
            if "source" not in itm: itm["source"] = "Smart Discovery"
            batch_items.append(itm)
            
        logger.info(f"[Genesis] 🚀 Shipping batch of {len(batch_items)} items to Registry...")
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{genesis_url}/pipeline/batch-intake",
                json={"auth_key": auth_key, "items": batch_items},
                timeout=30.0
            )

            if response.status_code == 201:
                result = response.json()
                logger.info(f"[Genesis] ✅ Batch Intake Successful: {result.get('processed')} records committed.")
            else:
                logger.error(f"[Genesis] ❌ Batch Intake failed ({response.status_code}): {response.text[:200]}")

    except Exception as e:
        logger.error(f"[Genesis] Batch Bridge failure: {e}")


# ─────────────────────────────────────────────────────────────────────────────
# MAIN PIPELINE RUNNER
# ─────────────────────────────────────────────────────────────────────────────
async def run_pipeline(run_id: str = None):
    """
    Full end-to-end pipeline with:
    - Parallel scraping (max concurrent via semaphore)
    - File-based 24hr cache
    - Dual AI extraction + cross-validation
    - Vision-based image verification
    - Kill-switch polling
    """
    if not run_id:
        run_id = f"RUN_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"

    scraper = UniversalScraper()
    extractor = AIExtractor()
    validator = DataValidator(threshold=75)
    
    # ── Dynamic Concurrency Scaling ──
    key_status = multi_key_rotator.get_status()
    total_active_keys = sum(p["count"] for p in key_status["provider_stats"].values())
    
    # Scale: 3 threads per key (safe overlap), capped at 30
    dynamic_limit = min(30, max(MAX_CONCURRENT, total_active_keys * 3))
    semaphore = asyncio.Semaphore(dynamic_limit)
    
    start = datetime.utcnow()
    logger.info(f"[Pipeline] 🚀 Starting Full Pipeline Run: {run_id}")
    logger.info(f"[Pipeline] ⚙️ Concurrency: {dynamic_limit} (Scaled by {total_active_keys} keys)")
    logger.info(f"[Pipeline] 📦 Cache stats: {_get_cache_stats()}")

    tasks = [
        orchestrate_item(key, source, scraper, extractor, validator, semaphore, run_id)
        for key, source in SOURCES.items()
    ]

    results = await asyncio.gather(*tasks, return_exceptions=True)

    # Count results and Filter successful extractions
    final_extracted = [r for r in results if isinstance(r, dict)]
    aborted = sum(1 for r in results if r == "aborted")
    failures = sum(1 for r in results if r is False or isinstance(r, Exception))

    # ── Phase 6: Continuous/Batch Commit ──
    if final_extracted:
        # Group in batches of 20 for safety
        for i in range(0, len(final_extracted), 20):
            batch = final_extracted[i:i + 20]
            await _genesis_batch_intake(batch, run_id)

    elapsed = (datetime.utcnow() - start).total_seconds()
    
    status = "completed" if aborted == 0 else "stopped"
    logger.info(f"[Pipeline] ✅ {status.upper()} — {len(final_extracted)} success, {failures} failed, {aborted} aborted — {elapsed:.1f}s total")
    
    return {
        "run_id": run_id,
        "status": status,
        "success": len(final_extracted), 
        "failed": failures, 
        "aborted": aborted,
        "duration_seconds": elapsed
    }


async def run_smart_discovery(prompt: str, run_id: str = None):
    """
    NEW: AI-led 'Smart Discovery' run.
    1. AI generates search queries -> Finds fresh URLs (DDG).
    2. OSM engine finds natural landmarks (Waterfalls, Peaks).
    3. Merges all into a high-quality ingestion queue.
    """
    if not run_id:
        run_id = f"SMART_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"
    
    logger.info(f"🧠 [SmartDiscovery] Starting AI-led discovery for: '{prompt}'")
    
    # Step 1: Web Discovery (AI + Search)
    ai_discovery = AIDiscovery()
    # We call generate_targets directly to get URLs before orchestrating
    targets = await ai_discovery.generate_targets(prompt)
    web_urls = targets.get("target_urls", [])
    
    # Step 2: OSM Discovery (Map Crawl)
    osm_results = await osm_discovery.discover_all_natural_gems()
    # For OSM, we generate 'search queries' or handle them as phantom sources
    
    # Step 3: Format as sources for the pipeline
    discovery_sources = {}
    for i, url in enumerate(web_urls):
        discovery_sources[f"DISC_{i}"] = {
            "name": f"Discovered: {url[:30]}...",
            "url": url,
            "type": "dynamic"
        }
    
    # Step 4: Run standard pipeline on discovered items
    scraper = UniversalScraper()
    extractor = AIExtractor()
    validator = DataValidator(threshold=75)
    
    # Dynamic semaphore for discovery too
    key_status = multi_key_rotator.get_status()
    total_active_keys = sum(p["count"] for p in key_status["provider_stats"].values())
    dynamic_limit = min(30, max(MAX_CONCURRENT, total_active_keys * 3))
    semaphore = asyncio.Semaphore(dynamic_limit)
    
    tasks = [
        orchestrate_item(key, src, scraper, extractor, validator, semaphore, run_id)
        for key, src in discovery_sources.items()
    ]
    
    if tasks:
        results = await asyncio.gather(*tasks, return_exceptions=True)
        final_extracted = [r for r in results if isinstance(r, dict)]
        
        if final_extracted:
            for i in range(0, len(final_extracted), 20):
                batch = final_extracted[i:i + 20]
                await _genesis_batch_intake(batch, run_id)
                
        logger.info(f"✅ [SmartDiscovery] Processed {len(final_extracted)} discovered targets.")
    else:
        logger.warning("[SmartDiscovery] No targets were discovered for this prompt.")

    return {"run_id": run_id, "discovered": len(discovery_sources)}


if __name__ == "__main__":
    asyncio.run(run_pipeline())
