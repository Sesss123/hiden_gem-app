# backend/pipeline/alert_manager.py
# NEW: Alert webhook system for critical pipeline failures + Telegram support

import os
import asyncio
import httpx
import json
from datetime import datetime, timedelta
from pipeline.logger import get_pipeline_logger

logger = get_pipeline_logger("AlertManager")

# ─── CONFIG ────────────────────────────────────────────────────────────────────
WEBHOOK_URL = os.getenv("ALERT_WEBHOOK_URL")          # Slack / Discord / custom
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")  # Placeholder in .env
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")
MIN_ALERT_INTERVAL_MINUTES = 10                        # Spam prevention
CONSECUTIVE_FAIL_THRESHOLD = 3                         # Alert after N failures


class AlertManager:
    def __init__(self):
        self._consecutive_failures = 0
        self._last_alert_time: datetime | None = None
        self._last_telegram_time: datetime | None = None

    def record_success(self):
        """Reset failure counter on any successful operation."""
        if self._consecutive_failures > 0:
            logger.info(f"[Alert] Failure streak reset after {self._consecutive_failures} failures.")
        self._consecutive_failures = 0

    def record_failure(self, context: str = ""):
        """Record a pipeline failure and fire alert if threshold reached."""
        self._consecutive_failures += 1
        logger.warning(f"[Alert] Failure #{self._consecutive_failures}: {context}")

        if self._consecutive_failures >= CONSECUTIVE_FAIL_THRESHOLD:
            asyncio.create_task(self._fire_alert(context))
        
    def fire_critical_alert(self, context: str):
        """Immediately fires an alert regardless of consecutive failure count (for risk scores)."""
        logger.error(f"[Alert] 🔥 CRITICAL ALERT: {context}")
        asyncio.create_task(self._fire_alert(context, is_critical=True))

    async def _fire_alert(self, context: str, is_critical: bool = False):
        """Send alert webhook and telegram message if cooldown period has passed."""
        now = datetime.utcnow()
        
        # 1. Handle Webhook
        if WEBHOOK_URL:
            if not self._is_on_cooldown(self._last_alert_time, now) or is_critical:
                payload = self._build_payload(context, is_critical)
                try:
                    async with httpx.AsyncClient(timeout=10.0) as client:
                        response = await client.post(WEBHOOK_URL, json=payload)
                        if response.status_code in (200, 204):
                            self._last_alert_time = now
                except Exception as e:
                    logger.error(f"[Alert] Webhook exception: {e}")
            else:
                logger.info("[Alert] Webhook cooldown active.")

        # 2. Handle Telegram
        if TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID:
            if not self._is_on_cooldown(self._last_telegram_time, now) or is_critical:
                await self._send_telegram_alert(context, is_critical)
                self._last_telegram_time = now
            else:
                logger.debug("[Alert] Telegram cooldown active.")
        else:
            if is_critical:
                logger.warning("[Alert] Telegram not configured for critical alert!")

    def _is_on_cooldown(self, last_time: datetime, now: datetime) -> bool:
        if not last_time:
            return False
        elapsed = (now - last_time).total_seconds() / 60
        return elapsed < MIN_ALERT_INTERVAL_MINUTES

    async def _send_telegram_alert(self, context: str, is_critical: bool):
        """Send message via Telegram Bot API."""
        emoji = "🚨" if is_critical else "⚠️"
        message = (
            f"{emoji} *TripMeAI Alert*\n\n"
            f"*Context*: {context}\n"
            f"*Time*: {datetime.utcnow().strftime('%H:%M:%S UTC')}\n"
            f"*Type*: {'CRITICAL' if is_critical else 'Repetitive Failure'}"
        )
        
        url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                await client.post(url, json={
                    "chat_id": TELEGRAM_CHAT_ID,
                    "text": message,
                    "parse_mode": "Markdown"
                })
                logger.info("[Alert] ✅ Telegram alert sent.")
        except Exception as e:
            logger.error(f"[Alert] Telegram API error: {e}")

    def _build_payload(self, context: str, is_critical: bool) -> dict:
        """Build Slack/Discord compatible alert payload."""
        ts = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
        prefix = "🚨 *CRITICAL*" if is_critical else "⚠️ *ALERT*"
        message = (
            f"{prefix} *TripMeAI Pipeline Alert*\n"
            f"*Failures:* {self._consecutive_failures} consecutive\n"
            f"*Context:* {context or 'Unknown error'}\n"
            f"*Time:* {ts}\n"
        )

        return {
            "text": message,
            "content": message,
            "username": "TripMeAI Genesis",
            "embeds": [{
                "title": f"{'🚨' if is_critical else '⚠️'} Pipeline Alert",
                "description": context,
                "color": 15158332 if is_critical else 15844367,
                "fields": [
                    {"name": "Failures", "value": str(self._consecutive_failures), "inline": True},
                    {"name": "Time", "value": ts, "inline": True},
                ]
            }]
        }

    def get_status(self) -> dict:
        """Returns the current alerting state for the dashboard."""
        return {
            "consecutive_failures": self._consecutive_failures,
            "last_alert": self._last_alert_time.isoformat() if self._last_alert_time else None,
            "is_healthy": self._consecutive_failures < CONSECUTIVE_FAIL_THRESHOLD
        }

# NEW: Lazy getter for singleton
_alert_manager = None

def get_alert_manager():
    global _alert_manager
    if _alert_manager is None:
        _alert_manager = AlertManager()
    return _alert_manager
