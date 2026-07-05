import logging
logger = logging.getLogger(__name__)

# backend/scripts/system_guard.py
import os
import shutil
import json
import asyncio
import argparse
from datetime import datetime
from pathlib import Path
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

load_dotenv()

# --- Config ---
BACKEND_DIR = Path(__file__).parent.parent
SQLITE_DB_PATH = BACKEND_DIR / "tripme.db"
BACKUP_ROOT = BACKEND_DIR / "backups"
MONGO_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017/tripme_genesis")

class SystemGuard:
    def __init__(self):
        self.client = AsyncIOMotorClient(MONGO_URI)
        self.db = self.client.get_default_database()
        BACKUP_ROOT.mkdir(exist_ok=True)

    async def backup(self):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir = BACKUP_ROOT / f"backup_{timestamp}"
        backup_dir.mkdir()

        logger.info(f"Starting System Backup to: {backup_dir}")

        # 1. SQLite Backup
        if SQLITE_DB_PATH.exists():
            shutil.copy2(SQLITE_DB_PATH, backup_dir / "tripme.db")
            logger.info(f"  [OK] SQLite: tripme.db backed up.")
        else:
            logger.info(f"  [WARN] SQLite: tripme.db NOT FOUND. Skipping.")

        def make_serializable(data):
            if isinstance(data, list):
                return [make_serializable(item) for item in data]
            if isinstance(data, dict):
                return {k: make_serializable(v) for k, v in data.items()}
            if hasattr(data, '__str__') and 'ObjectId' in str(type(data)):
                return str(data)
            if isinstance(data, datetime):
                return data.isoformat()
            return data

        # 2. MongoDB Backup
        mongo_backup_dir = backup_dir / "mongodb"
        mongo_backup_dir.mkdir()
        
        collections = await self.db.list_collection_names()
        for coll_name in collections:
            if coll_name.startswith("system."): continue
            
            data = []
            async for doc in self.db[coll_name].find():
                data.append(make_serializable(doc))
            
            with open(mongo_backup_dir / f"{coll_name}.json", "w") as f:
                json.dump(data, f, indent=2)
            logger.info(f"  [OK] MongoDB: '{coll_name}' exported ({len(data)} docs).")

        logger.info(f"\nBackup completed successfully! Location: {backup_dir}")
        logger.info(f"Hint: Copy this folder to a safe location (Cloud/USB).")
        return str(backup_dir.name)

    async def restore(self, backup_folder_name: str, skip_confirm: bool = False):
        backup_dir = (BACKUP_ROOT / backup_folder_name).resolve()
        if not str(backup_dir).startswith(str(BACKUP_ROOT.resolve())) or not backup_dir.exists():
            logger.info(f"RESTORE Error: Backup folder '{backup_folder_name}' not found or invalid in {BACKUP_ROOT}")
            return False

        logger.info(f"WARNING: This will OVERWRITE your current data with items from {backup_folder_name}")
        
        if not skip_confirm:
            confirm = input("Confirm Restore? (type 'yes' to proceed): ")
            if confirm.lower() != 'yes':
                logger.info("Restore cancelled.")
                return False

        # 1. Restore SQLite
        sqlite_backup = backup_dir / "tripme.db"
        if sqlite_backup.exists():
            shutil.copy2(sqlite_backup, SQLITE_DB_PATH)
            logger.info(f"  [OK] SQLite: tripme.db restored.")

        # 2. Restore MongoDB
        mongo_backup_dir = backup_dir / "mongodb"
        if mongo_backup_dir.exists():
            for json_file in mongo_backup_dir.glob("*.json"):
                coll_name = json_file.stem
                with open(json_file, "r") as f:
                    data = json.load(f)
                
                # Clear and Restore
                await self.db[coll_name].delete_many({})
                if data:
                    from bson import ObjectId
                    # Some data cleanup if needed
                    # await self.db[coll_name].insert_many(data) 
                    # Note: We skip re-converting ID to ObjectId to maintain consistency with the JSON export
                    # If the app expects ObjectIds, this might need refinement.
                    await self.db[coll_name].insert_many(data)
                logger.info(f"  [OK] MongoDB: '{coll_name}' restored ({len(data)} docs).")

        logger.info(f"\nSystem restore completed successfully!")
        return True

    def list_backups(self):
        backups = sorted([d.name for d in BACKUP_ROOT.iterdir() if d.is_dir()], reverse=True)
        if not backups:
            logger.info("No backups found.")
            return
        logger.info("Available Backups (Latest first):")
        for b in backups:
            logger.info(f"  - {b}")

async def main():
    parser = argparse.ArgumentParser(description="TripMe System Guard: Database Backup & Restore")
    parser.add_argument("action", choices=["backup", "restore", "list"], help="Action to perform")
    parser.add_argument("--folder", help="Backup folder name (required for restore)")
    
    args = parser.parse_args()
    guard = SystemGuard()

    if args.action == "backup":
        await guard.backup()
    elif args.action == "list":
        guard.list_backups()
    elif args.action == "restore":
        if not args.folder:
            logger.info("Error: --folder is required for restore action.")
            return
        await guard.restore(args.folder)

if __name__ == "__main__":
    asyncio.run(main())
