import os
import shutil
import re

BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))

def create_init_files():
    folders = ["api", "api/routers", "core", "models", "services"]
    for folder in folders:
        path = os.path.join(BACKEND_DIR, folder)
        os.makedirs(path, exist_ok=True)
        init_file = os.path.join(path, "__init__.py")
        if not os.path.exists(init_file):
            with open(init_file, "w") as f:
                pass

def move_routes():
    api_dir = os.path.join(BACKEND_DIR, "api")
    routers_dir = os.path.join(api_dir, "routers")
    os.makedirs(routers_dir, exist_ok=True)
    
    for filename in os.listdir(api_dir):
        if filename.startswith("routes_") and filename.endswith(".py"):
            new_name = filename.replace("routes_", "")
            src = os.path.join(api_dir, filename)
            dst = os.path.join(routers_dir, new_name)
            shutil.move(src, dst)
            print(f"Moved {filename} -> routers/{new_name}")

def update_imports():
    # Update main.py
    main_py = os.path.join(BACKEND_DIR, "main.py")
    if os.path.exists(main_py):
        with open(main_py, "r") as f:
            content = f.read()
        
        # Replace `from api.routes_X import router as X_router` with `from api.routers.X import router as X_router`
        content = re.sub(r'from api\.routes_([a-zA-Z0-9_]+) import', r'from api.routers.\1 import', content)
        
        with open(main_py, "w") as f:
            f.write(content)
            
    # Update all python files to use core.database instead of models.db or database
    for root, dirs, files in os.walk(BACKEND_DIR):
        for file in files:
            if file.endswith(".py") and file != "refactor_backend.py":
                filepath = os.path.join(root, file)
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                
                new_content = content.replace("from models.db import", "from core.database import")
                new_content = new_content.replace("from database import", "from core.database import")
                new_content = new_content.replace("import models.db", "import core.database")
                
                if new_content != content:
                    with open(filepath, "w", encoding="utf-8") as f:
                        f.write(new_content)

def cleanup_old_files():
    files_to_remove = [
        "database.py",
        "models/db.py",
    ]
    for f in files_to_remove:
        path = os.path.join(BACKEND_DIR, f)
        if os.path.exists(path):
            os.remove(path)
            print(f"Removed {f}")

if __name__ == "__main__":
    print("Starting backend refactoring...")
    create_init_files()
    move_routes()
    update_imports()
    cleanup_old_files()
    print("Backend refactoring completed successfully!")
