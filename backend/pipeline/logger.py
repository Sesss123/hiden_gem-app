# backend/pipeline/logger.py
# NEW: Structured JSON logging with colored console output and daily log files

import logging
import json
import os
from datetime import datetime
from pathlib import Path

# ─── ANSI Color Codes ──────────────────────────────────────────────────────────
COLORS = {
    "DEBUG":    "\033[36m",   # Cyan
    "INFO":     "\033[32m",   # Green
    "WARNING":  "\033[33m",   # Yellow
    "ERROR":    "\033[31m",   # Red
    "CRITICAL": "\033[35m",   # Magenta
    "RESET":    "\033[0m"
}

LOG_DIR = Path("data/logs")


class ColoredConsoleFormatter(logging.Formatter):
    """Pretty colored console formatter."""
    def format(self, record):
        color = COLORS.get(record.levelname, COLORS["RESET"])
        reset = COLORS["RESET"]
        ts = datetime.fromtimestamp(record.created).strftime("%H:%M:%S")
        prefix = f"{color}[{record.levelname[:4]}]{reset}"
        name = f"\033[90m{record.name}{reset}"
        msg = record.getMessage()

        # Add error details if present
        if record.exc_info:
            msg += f"\n{self.formatException(record.exc_info)}"

        return f"{prefix} {ts} {name}: {msg}"


class JsonFileHandler(logging.Handler):
    """Writes structured JSON logs to a rolling daily file."""
    def __init__(self):
        super().__init__()
        LOG_DIR.mkdir(parents=True, exist_ok=True)

    def emit(self, record):
        log_entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "line": record.lineno,
        }
        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)

        today = datetime.utcnow().strftime("%Y-%m-%d")
        log_file = LOG_DIR / f"pipeline_{today}.json"

        try:
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
        except Exception as e:
            print(f"[LogHandler] Failed to write log: {e}")


def get_pipeline_logger(name: str = "TripMeBackend") -> logging.Logger:
    """
    Returns a logger with:
    1. Colored console output
    2. Structured JSON file output (daily rolling)
    Configures root logger if name is TripMeBackend.
    """
    if name == "TripMeBackend":
        logger = logging.getLogger() # Root logger
    else:
        logger = logging.getLogger(name)

    if logger.handlers:
        return logger 

    logger.setLevel(logging.DEBUG)

    # ── Console Handler ──
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(ColoredConsoleFormatter())
    logger.addHandler(console_handler)

    # ── JSON File Handler ──
    file_handler = JsonFileHandler()
    file_handler.setLevel(logging.DEBUG)
    logger.addHandler(file_handler)

    return logger


def read_log_file(date: str = None) -> list:
    """Read log entries for a given date (default: today)."""
    if date is None:
        date = datetime.utcnow().strftime("%Y-%m-%d")
    log_file = LOG_DIR / f"pipeline_{date}.json"
    if not log_file.exists():
        return []
    entries = []
    with open(log_file, "r", encoding="utf-8") as f:
        for line in f:
            try:
                entries.append(json.loads(line.strip()))
            except json.JSONDecodeError:
                pass
    return entries


def get_log_summary(entries: list) -> dict:
    """Summarize log entries by level."""
    summary = {"INFO": 0, "WARNING": 0, "ERROR": 0, "CRITICAL": 0, "DEBUG": 0}
    for e in entries:
        level = e.get("level", "INFO")
        if level in summary:
            summary[level] += 1
    return summary
