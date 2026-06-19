from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class PipelineRunSchema(BaseModel):
    id: str
    name: Optional[str] = "Discovery"
    start_time: Optional[datetime]
    end_time: Optional[datetime]
    status: str
    progress: int = 0
    stats: dict = {"scraped": 0, "extracted": 0, "approved": 0, "rejected": 0}
    
    class Config:
        from_attributes = True

class VisitorStatSchema(BaseModel):
    place_id: Optional[str]
    name: Optional[str]
    view_count: int

class SearchStatSchema(BaseModel):
    term: str
    count: int

class AIUsageSummary(BaseModel):
    total_tokens: int = 0
    total_cost: float = 0.0
    model_breakdown: dict = {}

class AdminAnalyticsSchema(BaseModel):
    total_views: int
    top_places: List[VisitorStatSchema]
    popular_searches: List[SearchStatSchema]
    recent_runs: List[PipelineRunSchema]
    ai_usage: AIUsageSummary = AIUsageSummary()

class BulkActionRequest(BaseModel):
    ids: List[str]
    action: str # 'approve', 'reject', 'delete', 'change_category'
    value: Optional[str] = None # For category change
