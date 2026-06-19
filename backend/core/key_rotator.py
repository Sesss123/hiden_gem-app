# backend/core/key_rotator.py
# Unified Multi-Provider AI Key Rotation System — UPGRADED
#
# Manages keys for: Google Gemini, OpenAI, and Anthropic Claude.
# Keys stored in:
#   1. ENV vars (GOOGLE_API_KEY_N, OPENAI_API_KEY_N, ANTHROPIC_API_KEY_N)
#   2. data/api_keys_config.json (managed via Admin Dashboard)

import os
import json
import logging
from datetime import datetime, date
from pathlib import Path
from threading import Lock, RLock

logger = logging.getLogger("KeyRotator")

# ─── CONFIG ────────────────────────────────────────────────────────────────────
SOFT_LIMITS = {
    "google": 2400,    # Google free-tier limit per day per key
    "openai": 5000,    # Arbitrary limit for OpenAI (managed by balance mostly)
    "anthropic": 1000, # Arbitrary limit
    "deepseek": 3000,  # DeepSeek limit
    "groq": 10000,     # Groq is very generous for Llama 3
}

MAX_KEYS_PER_PROVIDER = 10
USAGE_FILE      = Path("data/key_usage.json")    # Per-key query counters
KEYS_CONFIG_FILE = Path("data/api_keys_config.json")  # Managed from dashboard

# ─────────────────────────────────────────────────────────────────────────────
class MultiProviderKeyRotator:
    """
    Manages partitioned pools of API keys for multiple AI providers.
    Supports hot-reloading from dashboard and handles usage tracking per provider.
    """

    def __init__(self):
        self._lock          = RLock()
        self._keys: dict[str, list[str]] = {"google": [], "openai": [], "anthropic": [], "deepseek": [], "groq": []}
        self._key_nicknames: dict[str, str] = {}  # key -> nickname
        self._key_providers: dict[str, str] = {}  # key -> provider
        self._usage: dict[str, dict] = {}
        self._current_indices: dict[str, int] = {"google": 0, "openai": 0, "anthropic": 0, "deepseek": 0, "groq": 0}

        self._migrate_old_config()
        self._reload_keys()
        self._load_usage()

    def _migrate_old_config(self):
        """Migrate legacy flat key config to tiered provider structure."""
        if not KEYS_CONFIG_FILE.exists():
            return
        try:
            with open(KEYS_CONFIG_FILE, "r") as f:
                data = json.load(f)
            
            # If "keys" is a list of simple dicts without "provider", tag as google
            modified = False
            if "keys" in data and isinstance(data["keys"], list):
                for entry in data["keys"]:
                    if "provider" not in entry:
                        entry["provider"] = "google"
                        modified = True
            
            if modified:
                logger.info("[KeyRotator] Migrating legacy keys config to multi-provider format.")
                self._save_keys_config(data["keys"])
        except Exception as e:
            logger.warning(f"[KeyRotator] Migration failed: {e}")

    # ─── Key Config File ────────────────────────────────────────────────────────
    def _load_keys_config(self) -> list[dict]:
        if not KEYS_CONFIG_FILE.exists():
            return []
        try:
            with open(KEYS_CONFIG_FILE, "r") as f:
                data = json.load(f)
            return data.get("keys", [])
        except Exception as e:
            logger.warning(f"[KeyRotator] Could not read keys config: {e}")
            return []

    def _save_keys_config(self, entries: list[dict]):
        KEYS_CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(KEYS_CONFIG_FILE, "w") as f:
            json.dump({"keys": entries, "updated_at": datetime.utcnow().isoformat()}, f, indent=2)

    def _reload_keys(self):
        self._keys = {"google": [], "openai": [], "anthropic": [], "deepseek": [], "groq": []}
        self._key_nicknames = {}
        self._key_providers = {}

        # ── Source 1: ENV vars ──
        mappings = {
            "google": ["GOOGLE_API_KEY", "GOOGLE_API_KEY_"],
            "openai": ["OPENAI_API_KEY", "OPENAI_API_KEY_"],
            "anthropic": ["ANTHROPIC_API_KEY", "ANTHROPIC_API_KEY_"],
            "deepseek": ["DEEPSEEK_API_KEY", "DEEPSEEK_API_KEY_"],
            "groq": ["GROQ_API_KEY", "GROQ_API_KEY_"]
        }

        for provider, prefixes in mappings.items():
            # Primary/Legacy
            p_key = os.getenv(prefixes[0], "").strip()
            if p_key:
                self._keys[provider].append(p_key)
                self._key_nicknames[p_key] = f"ENV {provider.capitalize()} Legacy"
                self._key_providers[p_key] = provider

            # Numbered
            for i in range(1, MAX_KEYS_PER_PROVIDER + 1):
                k = os.getenv(f"{prefixes[1]}{i}", "").strip()
                if k and k not in self._keys[provider]:
                    self._keys[provider].append(k)
                    self._key_nicknames[k] = f"ENV {provider.capitalize()} Key {i}"
                    self._key_providers[k] = provider

        # ── Source 2: JSON config ──
        for entry in self._load_keys_config():
            k = entry.get("key", "").strip()
            prov = entry.get("provider", "google")
            nick = entry.get("nickname", f"{prov.capitalize()} Key {len(self._keys[prov])+1}")
            
            if k and k not in self._keys.get(prov, []):
                if prov in self._keys:
                    self._keys[prov].append(k)
                    self._key_nicknames[k] = nick
                    self._key_providers[k] = prov

        # Initialize usage records
        for prov, keys in self._keys.items():
            for key in keys:
                if key not in self._usage:
                    self._usage[key] = {
                        "label": self._key_label(key),
                        "provider": prov,
                        "count": 0,
                        "exhausted": False,
                        "last_reset": str(date.today()),
                    }

        logger.info(f"[KeyRotator] ✅ Multi-provider keys loaded: { {p: len(k) for p, k in self._keys.items()} }")

    # ─── Usage Persistence ──────────────────────────────────────────────────────
    def _load_usage(self):
        if not USAGE_FILE.exists():
            return
        try:
            with open(USAGE_FILE, "r") as f:
                saved = json.load(f)
            today = str(date.today())
            for key, data in saved.items():
                if data.get("last_reset") != today:
                    data["count"] = 0
                    data["exhausted"] = False
                    data["last_reset"] = today
                # Only keep usage for keys we actually have loaded
                if key in self._key_providers:
                    self._usage[key] = data
        except Exception as e:
            logger.warning(f"[KeyRotator] Could not load usage file: {e}")

    def _persist_usage(self):
        try:
            USAGE_FILE.parent.mkdir(parents=True, exist_ok=True)
            with open(USAGE_FILE, "w") as f:
                json.dump(self._usage, f, indent=2)
        except Exception as e:
            logger.warning(f"[KeyRotator] Could not save usage file: {e}")

    @staticmethod
    def _key_label(key: str) -> str:
        if len(key) > 12:
            return f"{key[:8]}...{key[-4:]}"
        return "****"

    def _reset_daily_if_needed(self):
        today = str(date.today())
        for key, data in self._usage.items():
            if data.get("last_reset") != today:
                data["count"] = 0
                data["exhausted"] = False
                data["last_reset"] = today

    # ─── Core: Get Active Key ───────────────────────────────────────────────────
    def get_active_key(self, provider: str = "google") -> str | None:
        with self._lock:
            self._reset_daily_if_needed()
            provider_keys = self._keys.get(provider, [])
            if not provider_keys:
                return None
            
            soft_limit = SOFT_LIMITS.get(provider, 2000)
            
            for attempt in range(len(provider_keys)):
                idx = (self._current_indices[provider] + attempt) % len(provider_keys)
                key = provider_keys[idx]
                info = self._usage.get(key, {})
                if info.get("exhausted"):
                    continue
                if info.get("count", 0) >= soft_limit:
                    info["exhausted"] = True
                    logger.warning(f"[KeyRotator] {provider.upper()} Key {self._key_label(key)} exhausted — rotating.")
                    continue
                self._current_indices[provider] = idx
                return key
            
            logger.error(f"[KeyRotator] ❌ ALL {provider.upper()} API keys exhausted!")
            return None

    def increment(self, key: str):
        with self._lock:
            if key in self._usage:
                self._usage[key]["count"] += 1
                self._persist_usage()

    def mark_exhausted(self, key: str, provider: str = None, reason: str = "quota", model: str = "unknown"):
        with self._lock:
            if key in self._usage:
                self._usage[key]["exhausted"] = True
                prov = provider or self._key_providers.get(key, "unknown")
                label = self._key_label(key)
                nickname = self._key_nicknames.get(key, "Unknown")
                
                logger.warning(
                    f"🔴 [{prov.upper()}] Key EXHAUSTED: {label} ({nickname})\n"
                    f"   Reason: {reason} | Model: {model}"
                )
                
                p_keys = self._keys.get(prov, [])
                if p_keys and key in p_keys:
                    pos = p_keys.index(key)
                    self._current_indices[prov] = (pos + 1) % len(p_keys)
                self._persist_usage()

    # ─── DASHBOARD KEY MANAGEMENT ───────────────────────────────────────────────
    def list_keys_for_dashboard(self) -> list[dict]:
        with self._lock:
            self._reset_daily_if_needed()
            result = []
            config_entries = self._load_keys_config()
            config_keys = {e["key"]: e for e in config_entries}

            idx_global = 1
            for prov, keys in self._keys.items():
                soft_limit = SOFT_LIMITS.get(prov, 2000)
                for i, key in enumerate(keys):
                    info = self._usage.get(key, {})
                    count = info.get("count", 0)
                    exhausted = info.get("exhausted", False)
                    remaining = max(0, soft_limit - count)
                    source = "json_config" if key in config_keys else "env_var"
                    
                    result.append({
                        "index": idx_global,
                        "provider": prov,
                        "label": self._key_label(key),
                        "nickname": self._key_nicknames.get(key, f"Key {idx_global}"),
                        "count": count,
                        "limit": soft_limit,
                        "remaining": remaining,
                        "exhausted": exhausted,
                        "active": i == self._current_indices[prov] and not exhausted,
                        "health_pct": round((remaining / soft_limit) * 100, 1),
                        "source": source,
                        "can_delete": source == "json_config",
                    })
                    idx_global += 1
            return result

    def add_key(self, api_key: str, provider: str = "google", nickname: str = "") -> dict:
        api_key = api_key.strip()
        provider = provider.lower()
        if not api_key:
            return {"success": False, "error": "API key cannot be empty."}
        if provider not in self._keys:
            return {"success": False, "error": f"Unsupported provider: {provider}"}

        with self._lock:
            if api_key in self._key_providers:
                return {"success": False, "error": "This API key is already registered."}

            entries = self._load_keys_config()
            nickname = nickname.strip() or f"{provider.capitalize()} Key {len(self._keys[provider]) + 1}"
            entries.append({"key": api_key, "provider": provider, "nickname": nickname})
            self._save_keys_config(entries)

            self._reload_keys()
            self._load_usage()

            logger.info(f"[KeyRotator] ➕ Added {provider} key: {self._key_label(api_key)}")
            return {"success": True, "provider": provider, "label": self._key_label(api_key)}

    def remove_key(self, index: int) -> dict:
        with self._lock:
            all_keys = self.list_keys_for_dashboard()
            if index < 1 or index > len(all_keys):
                return {"success": False, "error": "Invalid index"}

            key_info = all_keys[index - 1]
            if not key_info["can_delete"]:
                return {"success": False, "error": "Cannot remove ENV keys via dashboard."}

            conf_entries = self._load_keys_config()
            # Match by nickname and provider to find the key to remove
            remaining = [e for e in conf_entries if not (e.get("nickname") == key_info["nickname"] and e.get("provider") == key_info["provider"])]
            
            if len(remaining) == len(conf_entries):
                return {"success": False, "error": "Key not found in config."}

            self._save_keys_config(remaining)
            self._reload_keys()
            self._load_usage()
            return {"success": True}

    def get_status(self) -> dict:
        """Overview for dashboard status cards and usage matrix."""
        with self._lock:
            self._reset_daily_if_needed()
            all_keys = self.list_keys_for_dashboard()
            
            total_keys = len(self._key_providers)
            total_used = sum(k["count"] for k in all_keys)
            total_limit = sum(k["limit"] for k in all_keys)
            total_remaining = sum(k["remaining"] for k in all_keys)
            
            # Aggregate by provider
            provider_stats = {}
            for prov in self._keys.keys():
                p_keys = [k for k in all_keys if k["provider"] == prov]
                provider_stats[prov] = {
                    "count": len(p_keys),
                    "used": sum(k["count"] for k in p_keys),
                    "limit": sum(k["limit"] for k in p_keys),
                    "remaining": sum(k["remaining"] for k in p_keys)
                }
            
            return {
                "total_keys": total_keys,
                "total_used": total_used,
                "total_limit": total_limit,
                "total_remaining_queries": total_remaining,
                "date": str(date.today()),
                "providers": list(self._keys.keys()),
                "provider_stats": provider_stats,
                "keys": all_keys
            }

# Global Singleton
multi_key_rotator = MultiProviderKeyRotator()
