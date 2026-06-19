# backend/pipeline/scraper.py
# UPGRADED: Retry logic, Rate Limiting, User-Agent Rotation, Timeout Management

import asyncio
import aiohttp
import random
import time
import logging
import hashlib
from pathlib import Path
from datetime import datetime, timedelta

try:
    from bs4 import BeautifulSoup
except ImportError:
    BeautifulSoup = None

try:
    from playwright.async_api import async_playwright
except ImportError:
    async_playwright = None

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("Scraper")

# ─── USER AGENT ROTATION POOL ─────────────────────────────────────────────────
USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3 Mobile/15E148 Safari/604.1",
]

# ─── RETRY CONFIG ─────────────────────────────────────────────────────────────
MAX_RETRIES = 3
BACKOFF_BASE = 2  # seconds: 2 → 4 → 8
REQUEST_TIMEOUT = 30  # seconds


class UniversalScraper:
    def __init__(self):
        self._request_count = 0
        self._last_request_time = {}
        self.cache_dir = Path("data/cache")
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self._browser = None
        self._playwright = None

    async def _init_browser(self):
        """Initialize a single browser instance for re-use."""
        if not self._browser:
            if not async_playwright:
                return None
            self._playwright = await async_playwright().start()
            self._browser = await self._playwright.chromium.launch(
                headless=True,
                args=[
                    "--disable-blink-features=AutomationControlled",
                    "--no-sandbox",
                ]
            )
        return self._browser

    async def shutdown(self):
        """Cleanly close the browser and playwright."""
        if self._browser:
            await self._browser.close()
            self._browser = None
        if self._playwright:
            await self._playwright.stop()
            self._playwright = None

    def _get_random_headers(self):
        """Return headers with a randomized User-Agent to avoid bot detection."""
        return {
            "User-Agent": random.choice(USER_AGENTS),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
        }

    async def _apply_rate_limit(self, domain: str, min_delay: float = 1.5):
        """
        Simple per-domain rate limiting.
        Ensures at least `min_delay` seconds between requests to the same domain.
        """
        now = time.time()
        last = self._last_request_time.get(domain, 0)
        wait_time = min_delay - (now - last)
        if wait_time > 0:
            logger.info(f"[RateLimit] Waiting {wait_time:.1f}s before hitting {domain}")
            await asyncio.sleep(wait_time)
        self._last_request_time[domain] = time.time()

    def _extract_domain(self, url: str) -> str:
        try:
            from urllib.parse import urlparse
            return urlparse(url).netloc
        except Exception:
            return url

    async def get_static(self, url: str) -> str | None:
        """
        Fetch static HTML using aiohttp.
        Includes: 3x exponential backoff retry, HTTP 429 auto-wait, timeout management.
        """
        domain = self._extract_domain(url)
        await self._apply_rate_limit(domain)

        for attempt in range(1, MAX_RETRIES + 1):
            try:
                headers = self._get_random_headers()
                timeout = aiohttp.ClientTimeout(total=REQUEST_TIMEOUT)

                logger.info(f"[Scraper] Static fetch attempt {attempt}/{MAX_RETRIES}: {url}")
                
                # Disable SSL verification for development environments if necessary
                connector = aiohttp.TCPConnector(ssl=False)
                async with aiohttp.ClientSession(headers=headers, timeout=timeout, connector=connector) as session:
                    async with session.get(url) as response:

                        # ── Handle Rate Limiting (429) ──
                        if response.status == 429:
                            retry_after = int(response.headers.get("Retry-After", BACKOFF_BASE * attempt * 2))
                            logger.warning(f"[Scraper] 429 Too Many Requests. Waiting {retry_after}s...")
                            await asyncio.sleep(retry_after)
                            continue

                        # ── Handle Forbidden / Not Found ──
                        if response.status in (403, 404):
                            logger.error(f"[Scraper] HTTP {response.status} for {url}. Aborting.")
                            return None

                        if response.status == 200:
                            html = await response.text()
                            return self.clean_html(html)
                        else:
                            logger.warning(f"[Scraper] Unexpected status {response.status} on attempt {attempt}")

            except asyncio.TimeoutError:
                logger.warning(f"[Scraper] Timeout on attempt {attempt}/{MAX_RETRIES} for {url}")
            except aiohttp.ClientConnectionError as e:
                logger.warning(f"[Scraper] Connection error on attempt {attempt}: {e}")
            except Exception as e:
                logger.error(f"[Scraper] Unexpected error on attempt {attempt}: {e}")

            # ── Exponential Backoff ──
            if attempt < MAX_RETRIES:
                backoff_delay = BACKOFF_BASE ** attempt
                logger.info(f"[Scraper] Retrying in {backoff_delay}s...")
                await asyncio.sleep(backoff_delay)

        logger.error(f"[Scraper] All {MAX_RETRIES} attempts failed for {url}")
        return None

    async def get_dynamic(self, url: str) -> str | None:
        """
        Fetch JavaScript-heavy pages using Playwright headless browser.
        Includes: retry logic, timeout management, stealth mode (random UA).
        """
        if async_playwright is None:
            logger.error("[Scraper] Playwright not installed. Run: pip install playwright && playwright install")
            return await self.get_static(url)  # Fallback to static

        domain = self._extract_domain(url)
        await self._apply_rate_limit(domain, min_delay=3.0)  # Longer delay for dynamic pages

        for attempt in range(1, MAX_RETRIES + 1):
            try:
                logger.info(f"[Scraper] Dynamic (Context Re-use) attempt {attempt}/{MAX_RETRIES}: {url}")

                browser = await self._init_browser()
                if not browser:
                    return await self.get_static(url)

                context = await browser.new_context(
                    user_agent=random.choice(USER_AGENTS),
                    viewport={"width": 1280, "height": 800}
                )
                
                page = await context.new_page()
                try:
                    # AGGRESSIVE BLOCKLIST: Block images, CSS, media, fonts, and ads
                    block_list = ["png", "jpg", "jpeg", "svg", "webp", "css", "woff", "woff2", "mp4", "gif", "adserver", "ads"]
                    await page.route("**/*.{" + ",".join(block_list) + "}", lambda route: route.abort())
                    
                    await page.goto(url, wait_until="domcontentloaded", timeout=REQUEST_TIMEOUT * 1000)
                    
                    # Wait for minimal content
                    await page.wait_for_selector("body", timeout=5000)
                    
                    html = await page.content()
                    return self.clean_html(html)
                finally:
                    await page.close()
                    await context.close()

            except Exception as e:
                logger.warning(f"[Scraper] Dynamic failure {attempt}/{MAX_RETRIES}: {e}")
                if attempt == MAX_RETRIES: return None
                await asyncio.sleep(BACKOFF_BASE ** attempt)

        logger.error(f"[Scraper] Dynamic scraping failed for {url} after {MAX_RETRIES} attempts")
        return None

    def clean_html(self, html: str) -> str:
        """
        Aggressively clean HTML to reduce token usage for AI extraction:
        - Removes scripts, styles, nav, footer, ads, sidebar, comments
        - Strips hidden elements and non-content noise
        - Normalizes whitespace
        """
        if BeautifulSoup is None:
            return html[:15000]

        soup = BeautifulSoup(html, "html.parser")

        # ── 1. Remove obvious boilerplate ──
        for element in soup(["script", "style", "nav", "footer", "header", 
                              "noscript", "iframe", "aside", "form", "button",
                              "svg", "canvas", "video", "audio", "head", "meta", "link"]):
            element.decompose()

        # ── 2. Remove common sidebar/ad/social classes ──
        noise_selectors = [
            ".sidebar", "#sidebar", ".widget", ".ads", ".advertisement", 
            ".social-share", ".newsletter", ".comments", "#comments",
            ".related-posts", ".breadcrumb-noise", ".nav-menu", ".footer-links",
            ".share-buttons", ".popover", ".modal", ".overlay", ".cookie-banner"
        ]
        for selector in noise_selectors:
            for element in soup.select(selector):
                element.decompose()

        # ── 3. Remove comment nodes ──
        from bs4 import Comment
        for comment in soup.find_all(string=lambda text: isinstance(text, Comment)):
            comment.extract()

        # ── 4. Extract text with preserved structure ──
        # We use get_text with a separator to avoid merging words
        text = soup.get_text(separator="\n", strip=True)
        
        # ── 5. Normalize whitespace ──
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        cleaned_text = "\n".join(lines)

        logger.info(f"[Scraper] Content cleaned: {len(html)} → {len(cleaned_text)} chars")
        return cleaned_text[:15000] # Cap for safety

    async def extract_main_image(self, url: str) -> str | None:
        """
        Specialized scraper to find the best representative image for a site.
        Includes special handling for Wikipedia 'Original' high-res images.
        """
        logger.info(f"[Scraper] Harvesting main image for: {url}")
        
        # We need the full HTML to find images, so we'll fetch without full cleaning
        headers = self._get_random_headers()
        try:
            async with aiohttp.ClientSession(headers=headers) as session:
                async with session.get(url, timeout=10) as response:
                    if response.status != 200: return None
                    html = await response.text()
                    soup = BeautifulSoup(html, "html.parser")
                    
                    # ── Strategy 1: OpenGraph Images (Standard) ──
                    og_image = soup.find("meta", property="og:image")
                    if og_image and og_image.get("content"):
                        return og_image["content"]

                    # ── Strategy 2: Wikipedia Specific ──
                    if "wikipedia.org" in url:
                        # Find the first image in the infobox
                        infobox = soup.find("table", class_="infobox")
                        if infobox:
                            img = infobox.find("img")
                            if img:
                                src = img.get("src")
                                if src:
                                    # Convert thumbnail to original
                                    # Wikipedia thumbnails look like: //upload.wikimedia.org/.../200px-Image.jpg
                                    # Original is: //upload.wikimedia.org/.../Image.jpg
                                    if "/thumb/" in src:
                                        parts = src.split("/")
                                        # Remove the thumb and the last scale part
                                        original_src = "/".join(parts[:-1]).replace("/thumb/", "/")
                                        return f"https:{original_src}" if original_src.startswith("//") else original_src
                                    return f"https:{src}" if src.startswith("//") else src

                    # ── Strategy 3: Large image search ──
                    imgs = soup.find_all("img")
                    # Filter for large-ish images
                    for img in imgs:
                        src = img.get("src")
                        if not src: continue
                        # Skip small icons
                        width = img.get("width")
                        if width and width.isdigit() and int(width) < 200: continue
                        if "logo" in src.lower() or "icon" in src.lower(): continue
                        
                        full_src = src if src.startswith("http") else f"https:{src}" if src.startswith("//") else None
                        if full_src: return full_src

        except Exception as e:
            logger.warning(f"[Scraper] Image extraction failed for {url}: {e}")
            
        return None

    def _get_cache_path(self, url: str) -> Path:
        """Generate a deterministic file path for a URL's cache."""
        url_hash = hashlib.md5(url.encode()).hexdigest()
        return self.cache_dir / f"{url_hash}.html"

    def get_cached(self, url: str, expiry_days: int = 7) -> str | None:
        """Retrieve content from local cache if it hasn't expired."""
        cache_path = self._get_cache_path(url)
        if cache_path.exists():
            # Check expiry
            mtime = datetime.fromtimestamp(cache_path.stat().st_mtime)
            if datetime.now() - mtime < timedelta(days=expiry_days):
                logger.info(f"[Scraper] Cache HIT: {url}")
                with open(cache_path, "r", encoding="utf-8") as f:
                    return f.read()
            else:
                logger.info(f"[Scraper] Cache EXPIRED: {url}")
        return None

    def _save_to_cache(self, url: str, content: str):
        """Save scraped content to local cache."""
        try:
            cache_path = self._get_cache_path(url)
            with open(cache_path, "w", encoding="utf-8") as f:
                f.write(content)
            logger.info(f"[Scraper] Cached content for: {url}")
        except Exception as e:
            logger.error(f"[Scraper] Failed to save cache: {e}")

    def is_cached(self, url: str, expiry_days: int = 7) -> bool:
        """Quick check if a URL has a valid cache entry."""
        cache_path = self._get_cache_path(url)
        if cache_path.exists():
            mtime = datetime.fromtimestamp(cache_path.stat().st_mtime)
            return datetime.now() - mtime < timedelta(days=expiry_days)
        return False

    async def scrape(self, url: str, type: str = "auto") -> str | None:
        """
        Smart scraping:
        1. Check Cache
        2. Decide Static vs Dynamic (Wikipedia is always static)
        3. Fetch & Save to Cache
        """
        # 1. Check Cache First
        cached = self.get_cached(url)
        if cached:
            return cached

        # 2. Decide strategy
        if type == "auto":
            if "wikipedia.org" in url:
                type = "static"
            else:
                type = "dynamic"
        
        # 3. Fetch
        content = None
        if type == "dynamic":
            content = await self.get_dynamic(url)
        else:
            content = await self.get_static(url)
            # FALLBACK: If static is suspiciously empty, try dynamic
            if (not content or len(content) < 500):
                logger.warning(f"[Scraper] Static content too thin ({len(content) if content else 0}). Falling back to Dynamic...")
                content = await self.get_dynamic(url)

        # 4. Save to cache
        if content:
            self._save_to_cache(url, content)

        return content
