#!/usr/bin/env bash
#
# Copy the transliteration data files from the upstream Lekho repo
# into the Xcode project's resources folder.
#
# Usage:
#   cd LekhoiOS && bash scripts/copy_data.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$(cd "$ROOT_DIR/../Lekho/data" && pwd)"
RESOURCE_DIR="$ROOT_DIR/Lekhi/Resources"

mkdir -p "$RESOURCE_DIR"

cp -f "$SOURCE_DIR/dictionary.json"  "$RESOURCE_DIR/dictionary.json"
cp -f "$SOURCE_DIR/autocorrect.json" "$RESOURCE_DIR/autocorrect.json"
cp -f "$SOURCE_DIR/suffix.json"      "$RESOURCE_DIR/suffix.json"
cp -f "$SOURCE_DIR/Probhat.json"     "$RESOURCE_DIR/probhat.json"

echo "✅ Data files copied to $RESOURCE_DIR"
ls -lh "$RESOURCE_DIR"
