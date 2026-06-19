# backend/models/database_models.py

from sqlalchemy import Column, String, Integer, Float, ForeignKey, DateTime, Text, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import datetime
import uuid

Base = declarative_base()

class District(Base):
    __tablename__ = "districts"
    id = Column(String, primary_key=True)
    name = Column(String, unique=True, nullable=False)
    province = Column(String)
    places = relationship("Place", back_populates="district")

class Category(Base):
    __tablename__ = "categories"
    id = Column(String, primary_key=True)
    name = Column(String, unique=True, nullable=False)
    slug = Column(String, unique=True, nullable=False)
    places = relationship("Place", back_populates="category")

class Place(Base):
    __tablename__ = "places"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    country = Column(String, default="Sri Lanka")
    district_id = Column(String, ForeignKey("districts.id"))
    category_id = Column(String, ForeignKey("categories.id"))
    description = Column(Text)
    lat = Column(Float)
    lng = Column(Float)
    ticket_range = Column(String)
    external_image_url = Column(String)
    
    # Financials
    ticket_price = Column(Integer, default=0)
    parking_fee = Column(Integer, default=0)
    
    # Logistics
    road_type = Column(String)
    mobile_signal = Column(String)
    parking_avail = Column(Integer, default=0)
    toilets = Column(Integer, default=0)
    food_nearby = Column(Integer, default=0)
    wheelchair_access = Column(Integer, default=0)
    stairs_heavy = Column(Integer, default=0)
    
    # Climate & Safety
    safety_level = Column(String, default="Safe")
    safety_note = Column(Text)
    rain_sensitivity = Column(String)
    monsoon_note = Column(Text)
    
    # Pipeline specific fields
    approved = Column(Integer, default=0) # 0: Pending, 1: Approved, -1: Rejected
    verified = Column(Integer, default=0)
    status = Column(String, default="pending")
    source = Column(String, default="Manual") # Track source (Manual vs AI)
    data_source = Column(String)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    # AR & Audio fields
    ar_supported = Column(Integer, default=0)
    ar_model_url = Column(String)
    ar_brand_name = Column(String)
    ar_model_scale = Column(Float, default=1.0)
    audio_url_si = Column(String)
    audio_url_en = Column(String)
    ar_hotspots = Column(Text)

    district = relationship("District", back_populates="places")
    category = relationship("Category", back_populates="places")
    images = relationship("PlaceImage", back_populates="place")

class PlaceImage(Base):
    __tablename__ = "place_images"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    place_id = Column(String, ForeignKey("places.id"))
    image_path = Column(String)
    image_type = Column(String) # 'internal' or 'external'
    is_cover = Column(Integer, default=0)
    
    place = relationship("Place", back_populates="images")

class PipelineRun(Base):
    __tablename__ = "pipeline_runs"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    start_time = Column(DateTime, default=datetime.datetime.utcnow)
    end_time = Column(DateTime)
    status = Column(String, default="running") # 'running', 'completed', 'failed'
    total_scraped = Column(Integer, default=0)
    total_extracted = Column(Integer, default=0)
    total_approved = Column(Integer, default=0)
    total_rejected = Column(Integer, default=0)
    logs = Column(Text) # JSON string of detailed logs

class VisitorAnalytics(Base):
    __tablename__ = "visitor_analytics"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    place_id = Column(String, ForeignKey("places.id"), nullable=True) # Mapping to a place if it's a view
    type = Column(String) # 'view', 'search', 'journey'
    search_term = Column(String)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    session_id = Column(String)
    meta_data = Column(Text) # JSON string for flexible data

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    firebase_uid = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, nullable=False)
    tier = Column(String, default="free") # 'free', 'premium', 'admin'
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    subscriptions = relationship("Subscription", back_populates="user")
    favorites = relationship("UserFavorite", back_populates="user")
    history = relationship("UserHistory", back_populates="user")

class Subscription(Base):
    __tablename__ = "subscriptions"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    provider = Column(String) # 'payhere', 'stripe'
    external_id = Column(String) # e.g. stripe subscription id or payhere order id
    status = Column(String) # 'active', 'expired', 'cancelled'
    expires_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User", back_populates="subscriptions")

class UserFavorite(Base):
    __tablename__ = "user_favorites"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    place_id = Column(String, ForeignKey("places.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User", back_populates="favorites")

class UserHistory(Base):
    __tablename__ = "user_history"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    place_id = Column(String, ForeignKey("places.id"), nullable=False)
    visited_at = Column(DateTime, default=datetime.datetime.utcnow)
    notes = Column(Text)
    
    user = relationship("User", back_populates="history")
