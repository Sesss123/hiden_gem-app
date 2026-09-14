import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "l10n"
LOCALES = ("en", "si", "ta", "ja", "ko", "ru")
PLACEHOLDER = re.compile(r"\{([A-Za-z_][A-Za-z0-9_]*)\}")


def load(path: Path):
    duplicates = []

    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                duplicates.append(key)
            result[key] = value
        return result

    data = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=pairs)
    return data, duplicates


catalogs = {}
failed = False
for locale in LOCALES:
    path = ROOT / f"app_{locale}.arb"
    try:
        catalogs[locale], duplicates = load(path)
        print(f"{path.name}: valid JSON, {len(catalogs[locale])} entries")
        if duplicates:
            failed = True
            print(f"  duplicate keys: {', '.join(sorted(set(duplicates)))}")
    except Exception as error:
        failed = True
        print(f"{path.name}: INVALID: {error}")

if "en" in catalogs:
    template = catalogs["en"]
    template_keys = {key for key in template if not key.startswith("@")}
    for locale, catalog in catalogs.items():
        if locale == "en":
            continue
        keys = {key for key in catalog if not key.startswith("@")}
        missing = sorted(template_keys - keys)
        extra = sorted(keys - template_keys)
        print(f"app_{locale}.arb: missing={len(missing)}, extra={len(extra)}")
        if missing:
            failed = True
            print("  missing: " + ", ".join(missing))
        if extra:
            print("  extra: " + ", ".join(extra))

        for key in sorted(template_keys & keys):
            source = template[key]
            translated = catalog[key]
            if not isinstance(source, str) or not isinstance(translated, str):
                continue
            expected = set(PLACEHOLDER.findall(source))
            actual = set(PLACEHOLDER.findall(translated))
            if expected != actual:
                failed = True
                print(f"  placeholder mismatch {key}: expected={sorted(expected)} actual={sorted(actual)}")

raise SystemExit(1 if failed else 0)
