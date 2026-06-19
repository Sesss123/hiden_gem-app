import sys
from pipeline.logger import get_pipeline_logger
# Configure root logger and app logger
logger = get_pipeline_logger("TripMeBackend")

print(">>> BACKEND STARTING: Initializing core modules...", flush=True)
from fastapi import FastAPI, Depends, Request, HTTPException
import logging
import os
from contextlib import asynccontextmanager
from core.security import get_current_user
from dotenv import load_dotenv
load_dotenv()
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from core.firebase_admin_init import init_firebase
from core.rate_limit import limiter

# Initialize Security & Database (Hybrid Strategy: MongoDB Primary, SQLite Buffer)
init_firebase()
print(">>> Firebase: Bridge connection active.", flush=True)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    print(">>> Startup: Background service engines active.", flush=True)
    yield
    # Shutdown logic (if any)
    print(">>> Shutdown: Cleaning up resources...", flush=True)

app = FastAPI(
    title="TripMeAI Hardened API", 
    version="2.5.0",
    lifespan=lifespan
)

# --- Middleware ---

# Rate Limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS Lockdown
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3006", # Genesis Admin Dashboard
        "http://localhost:3000", # Native Frontend (React/Next)
        "http://localhost:5173", # Vite Default
    ], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Routes ---

# Import modular routers
from api.routers.places import router as places_router
from api.routers.pipeline import router as pipeline_router
from api.routers.admin import router as admin_router
from api.routers.auth import router as auth_router
from api.routers.user import router as user_router
from api.routers.ai import router as ai_router
from api.routers.scheduler import router as scheduler_router

# Include Modularized Routes
app.include_router(pipeline_router)
app.include_router(places_router)
app.include_router(admin_router)
app.include_router(auth_router)
app.include_router(user_router)
app.include_router(ai_router)
app.include_router(scheduler_router)

# Static Files (Uploads)
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

@app.get("/")
async def root():
    return {"message": "TripMeAI Secure API is running", "version": "2.5.0-hardened"}

@app.get("/admin/stats")
async def legacy_admin_stats(user=Depends(get_current_user)):
    """Legacy alias to handle old UI clients bypassing the /api prefix"""
    from api.routers.admin import get_analytics_overview
    return await get_analytics_overview(user)


if __name__ == "__main__":
    import uvicorn
    # Use string reference "main:app" for Windows multiprocessing/reload stability
    uvicorn.run("main:app", host="0.0.0.0", port=8000)
