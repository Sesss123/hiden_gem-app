from pydantic import BaseModel, Field
from typing import List, Optional

# --- Base Models ---

class ImageModel(BaseModel):
    image_path: str
    thumbnail_path: Optional[str] = None
    caption: Optional[str] = None
    is_cover: bool = False

# --- Tiered Response Models ---

class PlacePublic(BaseModel):
    id: str
    name: str
    district_id: Optional[str] = None
    category_id: Optional[str] = None
    short_description: Optional[str] = Field(None, alias="description")
    tags: Optional[str] = None
    status: str
    images: List[ImageModel] = []

    class Config:
        populate_by_name = True

class PlaceVerified(PlacePublic):
    crowd_level: Optional[str] = None
    noise_level: Optional[str] = None
    safety_level: Optional[str] = None
    open_hours: Optional[str] = None
    parking_avail: Optional[int] = None
    toilets: Optional[int] = None
    food_nearby: Optional[int] = None
    mobile_signal: Optional[str] = None

class PlacePremium(PlaceVerified):
    scam_warning: Optional[str] = None
    safety_note: Optional[str] = None
    special_rules: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    address: Optional[str] = None
    monsoon_note: Optional[str] = None
    ai_summary: Optional[str] = None
    ticket_price: Optional[int] = None
    ticket_range: Optional[str] = None
    facilities: Optional[str] = None
    ar_supported: Optional[int] = None
    road_type: Optional[str] = None
    external_image_url: Optional[str] = None
    ar_model_url: Optional[str] = None
    ar_brand_name: Optional[str] = None
    ar_model_scale: Optional[float] = 1.0
    audio_url_si: Optional[str] = None
    audio_url_en: Optional[str] = None
    ar_hotspots: Optional[str] = None

class PlaceMap(BaseModel):
    id: str
    name: str
    lat: float
    lng: float
    category_id: Optional[str] = None
    district_id: Optional[str] = None
    thumbnail: Optional[str] = None
