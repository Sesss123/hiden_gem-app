import logging
logger = logging.getLogger(__name__)

import asyncio
import sys
import os
from pathlib import Path

# Add backend to sys.path
backend_path = Path(__file__).parent.parent
sys.path.append(str(backend_path))

from mas.supervisor import supervisor

async def test_sigiriya_mas():
    logger.info("[TEST] Starting Multi-Agent Investigation for Sigiriya...")
    
    try:
        # We run the supervisor
        # This will trigger: Researcher -> Auditor -> Verifier -> Advisor
        result = await supervisor.execute("Sigiriya Fortress", "Matale")
        
        logger.info("\n[RESULT] MAS Execution Complete!")
        logger.info(f"Confidence Score: {result.get('confidence_score')}%")
        logger.info(f"Final Destination Name: {result.get('final_result', {}).get('name')}")
        logger.info(f"Weather Safety: {result.get('final_result', {}).get('climate_safety', {}).get('safety_level')}")
        logger.info(f"Advisor Note: {result.get('final_result', {}).get('personalization', {}).get('advisor_note')}")
        
        logger.info("\n--- Reasoning Logs ---")
        for log in result.get("reasoning_logs", []):
            logger.info(f"[{log['agent']}] {log['action']}: {log['reasoning'][:100]}...")

    except Exception as e:
        logger.info(f"[ERROR] MAS Test Failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_sigiriya_mas())
