import asyncio
import sys
import os
from pathlib import Path

# Add backend to sys.path
backend_path = Path(__file__).parent.parent
sys.path.append(str(backend_path))

from mas.supervisor import supervisor

async def test_sigiriya_mas():
    print("[TEST] Starting Multi-Agent Investigation for Sigiriya...")
    
    try:
        # We run the supervisor
        # This will trigger: Researcher -> Auditor -> Verifier -> Advisor
        result = await supervisor.execute("Sigiriya Fortress", "Matale")
        
        print("\n[RESULT] MAS Execution Complete!")
        print(f"Confidence Score: {result.get('confidence_score')}%")
        print(f"Final Destination Name: {result.get('final_result', {}).get('name')}")
        print(f"Weather Safety: {result.get('final_result', {}).get('climate_safety', {}).get('safety_level')}")
        print(f"Advisor Note: {result.get('final_result', {}).get('personalization', {}).get('advisor_note')}")
        
        print("\n--- Reasoning Logs ---")
        for log in result.get("reasoning_logs", []):
            print(f"[{log['agent']}] {log['action']}: {log['reasoning'][:100]}...")

    except Exception as e:
        print(f"[ERROR] MAS Test Failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_sigiriya_mas())
