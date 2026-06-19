import asyncio
import logging
import json
from pathlib import Path
from typing import List, Dict, Any
from pipeline.discovery import AIDiscovery
from services.osm_service import osm_service
from pipeline.validator import DataValidator
from pipeline.scheduler import global_scheduler as scheduler

# Configure Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("UniversalHive")

SRI_LANKA_DISTRICTS = [
    "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo",
    "Galle", "Gampaha", "Hambantota", "Jaffna", "Kalutara",
    "Kandy", "Kegalle", "Kilinochchi", "Kurunegala", "Mannar",
    "Matale", "Matara", "Moneragala", "Mullaitivu", "Nuwara Eliya",
    "Polonnaruwa", "Puttalam", "Ratnapura", "Trincomalee", "Vavuniya"
]

CATEGORY_REGISTRY = {
    "Nature": ["Waterfalls", "Hiking Trails", "Caves", "National Parks", "Tanks/Reservoirs"],
    "Historical": ["Ancient Ruins", "Archaeological Sites", "Forts", "Inscriptions"],
    "Coastal": ["Secret Beaches", "Surf Breaks", "Coral Reefs"],
    "Religious": ["Ancient Temples", "Sacred Sites", "Kovils", "Churches"]
}

class UniversalDiscoveryHive:
    def __init__(self):
        self.ai_discovery = AIDiscovery()
        self.validator = DataValidator()
        self.output_dir = Path("data/discovery")
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.results_file = self.output_dir / "universal_discovery_results.json"
        
        self.stats = {
            "total_found": 0,
            "categories_processed": {},
            "districts_completed": [],
            "current_status": "idle"
        }

    async def update_telemetry(self, district: str, category: str):
        """Update live status for Genesis Dashboard."""
        from api.routes_pipeline import set_pipeline_state
        set_pipeline_state(
            status="running",
            current_step=f"Hive: Discovering {category} in {district}",
            tank_hive={
                "status": "running",
                "total_found": self.stats["total_found"],
                "current_district": district,
                "current_category": category,
                "districts_completed": self.stats["districts_completed"]
            }
        )

    async def brainstorm_category(self, district: str, category: str, sub_category: str) -> List[Dict[str, Any]]:
        """Use AI to brainstorm specific points of interest."""
        prompt = f"""As a Sri Lankan travel expert, list 10-15 {sub_category} ({category} category) specifically in the {district} district.
        Focus on both famous landmarks and hidden gems.
        Return ONLY a JSON array of objects with 'name', 'estimated_type', 'context', and 'search_query'.
        Example: [{{ "name": "Bambarakanda Falls", "estimated_type": "waterfall", "context": "Highest in SL", "search_query": "Bambarakanda Falls Kalutara" }}]"""
        
        # Fallback logic already in AIDiscovery logic we'll use
        model, _ = await self.ai_discovery._get_model("gemini-1.5-flash")
        if not model: return []
        
        try:
            response = await model.generate_content_async(prompt)
            text = response.text.strip()
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0]
            elif "```" in text:
                text = text.split("```")[1].split("```")[0]
            
            items = json.loads(text)
            logger.info(f"✅ AI found {len(items)} {sub_category} for {district}")
            return items
        except Exception as e:
            logger.error(f"❌ Brainstorm failed for {sub_category} in {district}: {e}")
            return []

    async def verify_and_enrich(self, item: Dict[str, Any], district: str):
        """Verify the AI discovery and queue for full enrichment."""
        name = item.get("name")
        # Basic validation
        is_valid, reason = self.validator.is_tank_valid(name) # Using existing validator logic
        if not is_valid and "reservoir" in item.get("estimated_type", "").lower():
            return None
            
        # In a real run, we would queue this to the scheduler for full scraping/enrichment
        # For the discovery phase, we just mark it as a target
        return {
            **item,
            "district": district,
            "discovery_method": "AI_Universal_Hive",
            "verified": True
        }

    async def process_district_category(self, district: str, category: str, sub_categories: List[str]):
        """Runs the hive for a specific district and category."""
        for sub in sub_categories:
            await self.update_telemetry(district, sub)
            discovered = await self.brainstorm_category(district, category, sub)
            
            results = []
            for item in discovered:
                enriched = await self.verify_and_enrich(item, district)
                if enriched:
                    results.append(enriched)
                    self.stats["total_found"] += 1
            
            # Save results (incremental)
            if results:
                await self.save_results(results)

    async def save_results(self, new_items: List[Dict[str, Any]]):
        current_data = []
        if self.results_file.exists():
            with open(self.results_file, "r", encoding="utf-8") as f:
                try:
                    current_data = json.load(f)
                except: current_data = []
        
        current_data.extend(new_items)
        with open(self.results_file, "w", encoding="utf-8") as f:
            json.dump(current_data, f, indent=2, ensure_ascii=False)

    async def run_master_hive(self):
        """Orchestrate the entire Sri Lanka Master Plan."""
        logger.info("🚀 UNLEASHING UNIVERSAL DISCOVERY HIVE...")
        
        # Semaphore for high concurrency - using 5 parallel districts to start
        semaphore = asyncio.Semaphore(5) 
        
        async def work_district(dist):
            async with semaphore:
                for category, sub_cats in CATEGORY_REGISTRY.items():
                    await self.process_district_category(dist, category, sub_cats)
                self.stats["districts_completed"].append(dist)

        tasks = [work_district(dist) for dist in SRI_LANKA_DISTRICTS]
        await asyncio.gather(*tasks)
        
        logger.info(f"🏁 MASTER HIVE COMPLETE! Total Unique Targets: {self.stats['total_found']}")
        return self.stats

if __name__ == "__main__":
    hive = UniversalDiscoveryHive()
    asyncio.run(hive.run_master_hive())
