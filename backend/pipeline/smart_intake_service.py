import logging
import asyncio
from typing import Dict, Any, Optional
from pipeline.scraper import UniversalScraper
from pipeline.ai_extractor import AIExtractor
from core.database import SessionLocal
from core.mongodb import get_mongo_db
from models.database_models import Place, District, Category
import uuid
from datetime import datetime

logger = logging.getLogger("SmartIntakeService")

class SmartIntakeService:
    def __init__(self):
        self.scraper = UniversalScraper()
        self.extractor = AIExtractor()

    async def process_url(self, url: str) -> Optional[Dict[str, Any]]:
        """
        Full lifecycle: Scrape URL -> Clean Content -> AI Extract.
        """
        logger.info(f"[SmartIntake] Starting processing for URL: {url}")
        
        try:
            # 1. Scrape content (Use dynamic by default for better quality)
            html_content = await self.scraper.scrape(url, type="dynamic")
            
            if not html_content:
                logger.error(f"[SmartIntake] Failed to scrape content from {url}")
                return None

            # 2. Extract structured data using AI
            # Extraction logic already handles cleaning and model fallback
            extracted_data = await self.extractor.extract_from_html(html_content)
            
            if not extracted_data:
                logger.error(f"[SmartIntake] AI failed to extract data from {url}")
                return None

            # 3. Add source metadata
            extracted_data["data_source"] = url
            
            # 4. Auto-Approval Logic
            score = extracted_data.get("_score", 0)
            if score >= 90:
                extracted_data["status"] = "approved"
                logger.info(f"✨ [SmartIntake] High confidence ({score}%). Flagging for auto-approval.")
            else:
                extracted_data["status"] = "pending"
            
            # 5. Genesis Intake (Hybrid Persistence: SQLite + MongoDB)
            await self._genesis_intake(extracted_data)
            await self._mongo_intake(extracted_data)
            
            logger.info(f"[SmartIntake] Successfully processed: {extracted_data.get('name', 'Unknown')}")
            return extracted_data

        except Exception as e:
            logger.error(f"[SmartIntake] Critical failure processing {url}: {e}")
            return None

    async def enrich_with_images_and_vision(self, data: dict) -> dict:
        """
        Enrich a single result with a high-quality image and vision AI metadata.
        """
        url = data.get("data_source")
        if not url: return data
        
        # 1. Harvest Hero Image if missing or low quality
        if not data.get("external_image_url") or "wikipedia" in data["external_image_url"]:
            image_url = await self.scraper.extract_main_image(url)
            if image_url:
                data["external_image_url"] = image_url
                logger.info(f"[SmartIntake] Found high-res hero image: {image_url[:60]}...")
        
        # 2. Apply Visual Intelligence
        enriched = await self.extractor.apply_vision_enrichment(data)
        return enriched

    async def process_batch(self, urls: list[str]) -> list[Optional[dict]]:
        """
        Processes multiple URLs:
        1. Parallel Scrape (reusing browser contexts)
        2. Batch AI Extraction (single AI call for the group)
        """
        logger.info(f"[SmartIntake] Batch processing {len(urls)} URLs")
        
        # 1. Parallel Scraping
        # We'll use asyncio.gather for scraping which now uses context re-use
        scraping_tasks = [self.scraper.scrape(url, type="dynamic") for url in urls]
        html_contents = await asyncio.gather(*scraping_tasks)
        
        valid_indices = [i for i, h in enumerate(html_contents) if h]
        valid_htmls = [html_contents[i] for i in valid_indices]
        
        if not valid_htmls:
            logger.warning("[SmartIntake] Batch scraping yielded 0 results.")
            return [None] * len(urls)

        # 2. Batch AI Extraction
        extracted_list = await self.extractor.extract_batch(valid_htmls)
        
        # 3. Re-assemble final results
        final_results = [None] * len(urls)
        for i, idx in enumerate(valid_indices):
            if i < len(extracted_list) and extracted_list[i]:
                item = extracted_list[i]
                item["data_source"] = urls[idx]
                item["status"] = "draft"
                final_results[idx] = item
        
        logger.info(f"[SmartIntake] Batch complete. Succeeded: {len([r for r in final_results if r])}/{len(urls)}")
        return final_results

    async def enrich_batch_results(self, results: list[dict]) -> list[dict]:
        """
        Parallel enrichment for a batch of results.
        """
        valid_indices = [i for i, r in enumerate(results) if r]
        if not valid_indices: return results
        
        tasks = [self.enrich_with_images_and_vision(results[i]) for i in valid_indices]
        enriched_items = await asyncio.gather(*tasks)
        
        for i, idx in enumerate(valid_indices):
            results[idx] = enriched_items[i]
            
        return results

    async def _genesis_intake(self, data: Dict[str, Any]):
        """
        Saves the extracted data to the SQLite database.
        Standardizes models and handles district/category mapping.
        """
        db = SessionLocal()
        try:
            name = data.get("name")
            district_name = data.get("district")
            category_name = data.get("category")
            
            if not name or not district_name:
                logger.warning("[GenesisIntake] Missing name or district. Skipping DB save.")
                return

            # Lookup District
            dist = db.query(District).filter(District.name.ilike(district_name)).first()
            if not dist:
                dist = District(id=str(uuid.uuid4())[:8], name=district_name)
                db.add(dist)
                db.flush()

            # Lookup Category
            cat = db.query(Category).filter(Category.name.ilike(category_name)).first()
            if not cat:
                cat = Category(id=str(uuid.uuid4())[:8], name=category_name, slug=category_name.lower())
                db.add(cat)
                db.flush()

            # Create Place
            new_place = Place(
                id=str(uuid.uuid4()),
                name=name,
                district_id=dist.id,
                category_id=cat.id,
                description=data.get("description"),
                lat=data.get("lat"),
                lng=data.get("lng"),
                ticket_range=data.get("financials", {}).get("ticket_range"),
                external_image_url=data.get("external_image_url"),
                status=data.get("status", "pending"),
                verified=1 if data.get("_score", 0) >= 90 else 0,
                data_source=data.get("data_source"),
                created_at=datetime.utcnow()
            )
            
            # Map financials/logistics if needed (Place model has specific columns)
            new_place.safety_level = data.get("climate_safety", {}).get("safety_level")
            new_place.safety_note = data.get("climate_safety", {}).get("safety_note")
            
            db.add(new_place)
            db.commit()
            logger.info(f"✅ [GenesisIntake] Saved {name} to tripme.db (Status: {new_place.status})")
            
        except Exception as e:
            db.rollback()
            logger.error(f"❌ [GenesisIntake] Failed to save to SQLite: {e}")
        finally:
            db.close()

    async def _mongo_intake(self, data: Dict[str, Any]):
        """
        Saves the extracted data to MongoDB.
        """
        try:
            mongo_db = await get_mongo_db()
            if mongo_db is not None:
                # Add timestamp
                data["created_at"] = datetime.utcnow()
                # Check for existing place by name
                existing = await mongo_db.places.find_one({"name": data.get("name")})
                if existing:
                    await mongo_db.places.update_one({"name": data.get("name")}, {"$set": data})
                    logger.info(f"🔄 [MongoIntake] Updated {data.get('name')} in MongoDB.")
                else:
                    await mongo_db.places.insert_one(data)
                    logger.info(f"✅ [MongoIntake] Saved {data.get('name')} to MongoDB.")
        except Exception as e:
            logger.error(f"❌ [MongoIntake] Failed to save to MongoDB: {e}")

    async def shutdown(self):
        """Cleanup resources."""
        await self.scraper.shutdown()

# Singleton instance
smart_intake_service = SmartIntakeService()
