#!/usr/bin/env bash
#
# Canonical RELEASE build for Hidden Gems SL — always obfuscated.
#
# The ONLY supported way to produce a release artifact. Always passes
# --obfuscate --split-debug-info so a release can never ship un-obfuscated by
# accident, and loads all --dart-define secrets from dart_defines.json
# (gitignored). Symbols go to symbols/<target>/ — KEEP THEM for Crashlytics
# de-obfuscation.
#
# Usage:  ./scripts/build_release.sh [apk|appbundle|ipa]   (default: appbundle)

set -euo pipefail

TARGET="${1:-appbundle}"
case "$TARGET" in
  apk|appbundle|ipa) ;;
  *) echo "Invalid target '$TARGET' (use apk|appbundle|ipa)" >&2; exit 1 ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ ! -f dart_defines.json ]; then
  echo "Missing dart_defines.json. Copy dart_defines.example.json to dart_defines.json and fill it in." >&2
  exit 1
fi

mkdir -p "symbols/$TARGET"

echo "Building RELEASE ($TARGET), obfuscated, symbols -> symbols/$TARGET"

flutter build "$TARGET" \
  --release \
  --obfuscate \
  --split-debug-info="symbols/$TARGET" \
  --dart-define-from-file=dart_defines.json

echo "Done. Obfuscation symbols saved in symbols/$TARGET — archive them for Crashlytics."
