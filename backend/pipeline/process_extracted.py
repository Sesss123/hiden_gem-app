# backend/pipeline/process_extracted.py

import asyncio
import os
import logging
from ai_extractor import AIExtractor

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("Processor")

RAW_DATA_DIR = "data/raw"

async def process_all():
    # Load API keys (ensure they are in .env or environment)
    extractor = AIExtractor()
    
    if not os.path.exists(RAW_DATA_DIR):
        logger.error(f"Raw data directory {RAW_DATA_DIR} not found.")
        return

    files = [f for f in os.listdir(RAW_DATA_DIR) if f.endswith(".html")]
    
    logger.info(f"Found {len(files)} raw files to process.")
    
    for filename in files:
        logger.info(f"Processing: {filename}")
        
        filepath = os.path.join(RAW_DATA_DIR, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            html_content = f.read()
            
        # 1. Primary Extraction
        data = await extractor.extract_from_html(html_content)
        
        if data:
            # 2. Validation
            is_valid = await extractor.validate_with_gemini(html_content, data)
            
            if is_valid:
                # 3. Save result
                await extractor.save_extracted(data, filename)
            else:
                logger.error(f"Validation failed for {filename}")
        else:
            logger.error(f"Extraction failed for {filename}")

if __name__ == "__main__":
    asyncio.run(process_all())
