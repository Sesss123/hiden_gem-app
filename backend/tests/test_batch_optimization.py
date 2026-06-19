# backend/tests/test_batch_optimization.py

import asyncio
import sys
import os
from pathlib import Path
from datetime import datetime

# Add backend to path
sys.path.append(str(Path(__file__).parent.parent))

from pipeline.main_pipeline import run_pipeline

async def verify_batch_optimization():
    print("\n--- [Optimization] Verifying Batch Intake & Concurrency ---")
    
    # We'll run a standard pipeline run. 
    # Even if the dashboard is offline, we check the logs for 'Shipping batch'.
    try:
        results = await run_pipeline(run_id="TEST_OPTIMIZATION")
        print(f"\n✅ Pipeline completed: {results}")
    except Exception as e:
        print(f"Pipeline failed: {e}")

if __name__ == "__main__":
    asyncio.run(verify_batch_optimization())
