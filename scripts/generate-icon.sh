#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$ROOT/Resources/AudioBoost.icns"
ICONSET="$(mktemp -d)/AudioBoost.iconset"

cleanup() {
  rm -rf "$(dirname "$ICONSET")"
}
trap cleanup EXIT

swift "$ROOT/scripts/generate-icon.swift" "$ICONSET"
iconutil -c icns "$ICONSET" -o "$OUTPUT"

echo "Wrote $OUTPUT"
