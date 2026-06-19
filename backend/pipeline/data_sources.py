# backend/pipeline/data_sources.py
from abc import ABC, abstractmethod

class BaseSource(ABC):
    def __init__(self, key, name, url, type="static", selectors=None):
        self.key = key
        self.name = name
        self.url = url
        self.type = type
        self.selectors = selectors

    @abstractmethod
    def transform(self, data: dict) -> dict:
        """Apply source-specific cleaning logic."""
        return data

# --- Specific Source Implementations ---

class SLTDASource(BaseSource):
    def transform(self, data: dict) -> dict:
        # Custom logic for SLTDA source if needed
        return data

class ArchaeologySource(BaseSource):
    def transform(self, data: dict) -> dict:
        # Example: Archaeology data often needs name cleaning
        if data.get("name"):
            data["name"] = data["name"].split("|")[0].strip()
        return data

class CCFSource(BaseSource):
    def transform(self, data: dict) -> dict:
        return data

class LakdasunSource(BaseSource):
    def transform(self, data: dict) -> dict:
        # Lakdasun often has forum tags or user signatures in descriptions
        if data.get("description"):
            # Simple cleaning logic
            data["description"] = data["description"].split("---")[0].strip()
        return data

class YamuSource(BaseSource):
    def transform(self, data: dict) -> dict:
        # Yamu is great for food and active lifestyle spots
        if not data.get("category"):
            data["category"] = "Lifestyle"
        return data

# --- Registry ---

SOURCES = {
    "SLTDA": SLTDASource(
        key="SLTDA",
        name="Sri Lanka Tourism Development Authority",
        url="https://www.sltda.gov.lk/en/tourist-attractions",
        type="static",
        selectors=".attraction-card"
    ),
    "ARCHAEOLOGY": ArchaeologySource(
        key="ARCHAEOLOGY",
        name="Department of Archaeology",
        url="http://www.archaeology.gov.lk/historical-places/",
        type="dynamic",
        selectors="article"
    ),
    "CCF": CCFSource(
        key="CCF",
        name="Central Cultural Fund",
        url="https://ccf.gov.lk/heritage-sites/",
        type="static",
        selectors=".site-card"
    ),
    "LAKDASUN": LakdasunSource(
        key="LAKDASUN",
        name="Lakdasun Heritage",
        url="https://lakdasun.org/forum/",
        type="static",
        selectors=".postbody"
    ),
    "YAMU": YamuSource(
        key="YAMU",
        name="Yamu.lk Lifestyle",
        url="https://www.yamu.lk/places/",
        type="static",
        selectors=".place-card"
    )
}

def get_source(key: str) -> BaseSource:
    return SOURCES.get(key)
