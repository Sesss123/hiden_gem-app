# backend/pipeline/search_engine.py

import asyncio
import logging
from typing import List, Dict, Any
from duckduckgo_search import DDGS

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("SearchEngine")

class SearchEngine:
    def __init__(self):
        self.ddgs = DDGS()

    async def search(self, query: str, max_results: int = 10) -> List[Dict[str, str]]:
        """
        Performs a real-time web search using DuckDuckGo.
        Returns a list of dicts with 'title', 'href' (the link), and 'body'.
        """
        logger.info(f"[SearchEngine] 🔍 Looking for: '{query}'")
        try:
            # DDGS is synchronous in current installed version
            def _sync_search():
                # We create a new instance per call for thread safety
                with DDGS() as ddgs:
                    return list(ddgs.text(query, max_results=max_results))
            
            results = await asyncio.to_thread(_sync_search)
            logger.info(f"[SearchEngine] ✅ Found {len(results)} matches for '{query}'")
            return results
        except Exception as e:
            logger.error(f"[SearchEngine] ❌ Search failed for '{query}': {e}")
            return []

    async def search_images(self, query: str, max_results: int = 5) -> List[Dict[str, str]]:
        """
        Performs an image search using DuckDuckGo.
        Returns a list of dicts with 'title', 'image' (URL), and 'source'.
        """
        logger.info(f"[SearchEngine] 🖼️ Searching images for: '{query}'")
        try:
            def _sync_img_search():
                with DDGS() as ddgs:
                    return list(ddgs.images(query, max_results=max_results))
            
            results = await asyncio.to_thread(_sync_img_search)
            return results
        except Exception as e:
            logger.error(f"[SearchEngine] ❌ Image search failed for '{query}': {e}")
            return []

    async def batch_search(self, queries: List[str], max_results_per_query: int = 5) -> List[str]:
        """
        Executes multiple searches in parallel and returns a deduplicated list of URLs.
        """
        tasks = [self.search(q, max_results_per_query) for q in queries]
        search_results = await asyncio.gather(*tasks)
        
        # Extract unique URLs
        unique_urls = set()
        for results in search_results:
            for r in results:
                if 'href' in r:
                    unique_urls.add(r['href'])
        
        logger.info(f"[SearchEngine] 🚀 Batch search complete. Total unique URLs: {len(unique_urls)}")
        return list(unique_urls)

# Singleton instance
search_engine = SearchEngine()

if __name__ == "__main__":
    # Test run
    async def main():
        res = await search_engine.search("best hidden waterfalls in Sri Lanka site:lakdasun.org", 5)
        for r in res:
            print(f"- {r['title']}: {r['href']}")
            
    asyncio.run(main())
