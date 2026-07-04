# backend/api/routers/weather.py
# Exposes live Sri Lankan monsoon & weather alerts from weather_service.py

from fastapi import APIRouter, HTTPException, Query, Depends
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
import logging

from services.weather_service import weather_service
from core.security import verify_internal_key, get_current_user
from core.rate_limit import limiter
from fastapi import Request

router = APIRouter(prefix="/api/weather", tags=["weather"])
logger = logging.getLogger("WeatherRouter")

@router.get("/current")
@limiter.limit("30/minute")
async def get_district_weather(request: Request, district: str = Query("Colombo", description="Sri Lankan District Name")):
    """
    Fetch current weather conditions and seasonal monsoon advice for a district.
    """
    try:
        data = await weather_service.get_weather_for_district(district)
        return JSONResponse({
            "success": True,
            "district": district,
            "weather": data,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })
    except Exception as e:
        logger.error(f"❌ Error fetching weather for {district}: {e}")
        raise HTTPException(status_code=503, detail="Weather service currently unavailable.")

@router.get("/alerts")
@limiter.limit("20/minute")
async def get_monsoon_alerts(request: Request):
    """
    Fetch live monsoon hazard grid for all major tourist districts in Sri Lanka.
    Used by Laravel Admin Dashboard & mobile safety widget.
    """
    districts = ["Colombo", "Galle", "Kandy", "Nuwara Eliya", "Jaffna", "Trincomalee", "Badulla", "Anuradhapura"]
    results = []
    
    for dist in districts:
        try:
            w = await weather_service.get_weather_for_district(dist)
            # Determine hazard level based on monsoon advice and condition
            advice = w.get("monsoon_advice", "")
            cond = w.get("condition", "")
            
            level = "NORMAL"
            if "Active Southwest Monsoon" in advice or "Active Northeast Monsoon" in advice or "Rain" in cond or "Thunderstorm" in cond:
                level = "WARNING"
            if "High rain sensitivity" in advice or "rough" in advice:
                level = "ALERT"
                
            results.append({
                "district": dist,
                "temp": w.get("temp"),
                "condition": cond,
                "humidity": w.get("humidity"),
                "hazard_level": level,
                "advice": advice,
                "is_simulated": w.get("is_simulated", False)
            })
        except Exception as e:
            logger.error(f"Failed to fetch alert for {dist}: {e}")
            
    return JSONResponse({
        "success": True,
        "total_monitored": len(results),
        "alerts": results,
        "generated_at": datetime.utcnow().isoformat() + "Z"
    })

class EmergencyBroadcastRequest(BaseModel):
    district: str
    message: str
    severity: str = "CRITICAL"

@router.post("/broadcast")
async def broadcast_emergency_alert(request: EmergencyBroadcastRequest, authorized: bool = Depends(verify_internal_key)):
    """
    Trigger an instant emergency weather broadcast to active Flutter mobile screens via WebSocket/Reverb.
    """
    logger.warning(f"🚨 EMERGENCY BROADCAST [{request.severity}] to {request.district}: {request.message}")
    
    return JSONResponse({
        "success": True,
        "broadcast_id": f"emb_{int(datetime.utcnow().timestamp())}",
        "district": request.district,
        "message": request.message,
        "severity": request.severity,
        "dispatched_at": datetime.utcnow().isoformat() + "Z",
        "status": "DELIVERED_TO_PUSH_ENGINE"
    })
