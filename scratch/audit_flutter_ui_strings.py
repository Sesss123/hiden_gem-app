"""Reports likely user-facing Dart literals that bypass AppLocalizations.

Read-only audit. Run from the repository root:
  python scratch/audit_flutter_ui_strings.py
"""
from pathlib import Path
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parents[1]
FILES = [*ROOT.glob("lib/presentation/**/*.dart"), *ROOT.glob("lib/features/**/*.dart")]
CALL = re.compile(r"(?:Text|Tooltip|SnackBar|AppBar|InputDecoration|Semantics|showDialog)\s*\([^\n]*?(['\"])(.+?)\1")
NAMED = re.compile(r"(?:labelText|hintText|helperText|errorText|semanticLabel|tooltip|message|title|subtitle)\s*:\s*(['\"])(.+?)\1")
SKIP = re.compile(r"^(?:https?://|assets/|[a-z0-9_.-]+)$")

hits = []
for path in FILES:
    text = path.read_text(encoding="utf-8")
    for number, line in enumerate(text.splitlines(), 1):
        stripped = line.lstrip()
        if stripped.startswith("//") or "AppLocalizations" in line or "l10n." in line:
            continue
        for matcher in (CALL, NAMED):
            match = matcher.search(line)
            if match and not SKIP.fullmatch(match.group(2).strip()):
                hits.append((path.relative_to(ROOT).as_posix(), number, match.group(2)))
                break

for path, number, value in hits:
    print(f"{path}:{number}: {value}")
print(f"\nTOTAL_LIKELY_USER_FACING={len(hits)}")
