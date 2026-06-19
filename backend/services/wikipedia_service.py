import httpx
import logging
from typing import Optional

logger = logging.getLogger("WikipediaService")

class WikipediaService:
    def __init__(self):
        self.base_url = "https://en.wikipedia.org/w/api.php"

    async def get_summary(self, title: str):
        """
        Fetch a short summary from Wikipedia for a given title.
        """
        try:
            async with httpx.AsyncClient() as client:
                headers = {"User-Agent": "TripMeAI-Bot/1.0 (https://tripme.ai; contact@tripme.ai)"}
                params = {
                    "action": "query",
                    "format": "json",
                    "prop": "extracts",
                    "exintro": True,
                    "explaintext": True,
                    "titles": title,
                    "redirects": 1
                }
                
                response = await client.get(self.base_url, params=params, headers=headers)
                data = response.json()
                
                pages = data.get("query", {}).get("pages", {})
                if not pages:
                    return None
                
                # Get the first page in the dictionary
                page_id = next(iter(pages))
                if page_id == "-1":
                    logger.warning(f"📖 No Wikipedia page found for: {title}")
                    return None
                
                return pages[page_id].get("extract", "")

        except Exception as e:
            logger.error(f"❌ Wikipedia API Error: {e}")
            return None

    async def get_page_image(self, title: str, size: int = 800) -> Optional[str]:
        """
        Fetch the main thumbnail/image URL for a Wikipedia page.
        """
        try:
            async with httpx.AsyncClient() as client:
                headers = {"User-Agent": "TripMeAI-Bot/1.0 (https://tripme.ai; contact@tripme.ai)"}
                params = {
                    "action": "query",
                    "format": "json",
                    "prop": "pageimages",
                    "pithumbsize": size,
                    "titles": title,
                    "redirects": 1
                }
                
                response = await client.get(self.base_url, params=params, headers=headers)
                data = response.json()
                pages = data.get("query", {}).get("pages", {})
                
                if not pages: return None
                page_id = next(iter(pages))
                if page_id == "-1": return None
                
                return pages[page_id].get("thumbnail", {}).get("source")
        except Exception as e:
            logger.error(f"❌ Wikipedia Image Error: {e}")
            return None

wikipedia_service = WikipediaService()
