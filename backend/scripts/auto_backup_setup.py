import logging
logger = logging.getLogger(__name__)

# backend/scripts/auto_backup_setup.py
import os
import subprocess
import sys
from pathlib import Path

def setup_task():
    script_dir = Path(__file__).parent.absolute()
    bat_file = script_dir / "run_backup.bat"
    
    if not bat_file.exists():
        logger.info(f"Error: {bat_file} not found.")
        return

    task_name = "TripMe_Daily_Backup"
    bat_path = str(bat_file)

    logger.info(f"Setting up Daily Backup Task: {task_name}")
    logger.info(f"Backup script: {bat_path}")

    # Use schtasks to create a daily task at 12:00 AM
    # /SC DAILY = Daily frequency
    # /ST 00:00 = Start time (Midnight)
    # /F = Force (overwrite if exists)
    try:
        cmd = [
            "schtasks", "/create", 
            "/tn", task_name, 
            "/tr", f'"{bat_path}"', 
            "/sc", "daily", 
            "/st", "00:00", 
            "/f"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            logger.info("\nSUCCESS: Daily backup task has been scheduled for 12:00 AM.")
            logger.info("You can see it in 'Windows Task Scheduler' under the name 'TripMe_Daily_Backup'.")
        else:
            logger.info("\nERROR registering task:")
            logger.info(result.stderr)
            if "Access is denied" in result.stderr:
                logger.info("\nSuggestion: Try running your terminal as Administrator.")
            
    except Exception as e:
        logger.info(f"An error occurred: {e}")

if __name__ == "__main__":
    setup_task()
