# backend/models/pipeline_models.py
from pydantic import BaseModel, Field, field_validator
from typing import Dict, Any, Optional, List
from datetime import datetime
from core.config import SL_LAT_MIN, SL_LAT_MAX, SL_LNG_MIN, SL_LNG_MAX

class Financials(BaseModel):
    ticket_price: int = 0
    ticket_range: str = ""
    parking_fee: int = 0
    cost_min: int = 0
    cost_max: int = 0

class Logistics(BaseModel):
    road_type: str = "Paved"
    mobile_signal: str = "Moderate"
    parking_avail: int = Field(0, description="0 or 1")
    toilets: int = Field(0, description="0 or 1")
    food_nearby: int = Field(0, description="0 or 1")
    wheelchair_access: int = Field(0, description="0 or 1")
    stairs_heavy: int = Field(0, description="0 or 1")
    duration_min: int = 0
    is_indoor: int = 0
    open_hours: str = ""
    address: str = ""

class ClimateSafety(BaseModel):
    safety_level: str = "Safe"
    safety_note: str = ""
    rain_sensitivity: str = "Outdoor"
    monsoon_note: str = ""
    scam_warning: str = ""
    best_time: str = ""

class PlaceExtraction(BaseModel):
    name: str
    description: str
    district: str
    category: str
    lat: float
    lng: float
    financials: Financials
    logistics: Logistics
    climate_safety: ClimateSafety
    ar_supported: int = 0
    external_image_url: Optional[str] = None

    @field_validator("lat")
    def validate_lat(cls, v):
        if not (SL_LAT_MIN <= v <= SL_LAT_MAX):
            return v  # We will flag this in validator.py
        return v

    @field_validator("lng")
    def validate_lng(cls, v):
        if not (SL_LNG_MIN <= v <= SL_LNG_MAX):
            return v
        return v

class AIUsageLog(BaseModel):
    run_id: str
    model: str
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    cost_estimate: float
    timestamp: datetime = Field(default_factory=datetime.now)
    success: bool = True
    error: Optional[str] = None
