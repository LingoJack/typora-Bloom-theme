#!/usr/bin/env bash
set -euo pipefail

REPO="webkubor/typora-Bloom-theme"
ZIP_NAME="Bloom-theme.zip"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# --- Locate Typora themes directory ---
find_themes_dir() {
  local candidates=(
    "$APPDATA/Typora/themes"            # Windows
    "$HOME/Library/Application Support/abnerworks.Typora/themes"  # macOS
    "$HOME/.config/Typora/themes"       # Linux
  )
  for d in "${candidates[@]}"; do
    if [ -d "$d" ]; then
      echo "$d"
      return 0
    fi
  done
  return 1
}

THEMES_DIR=$(find_themes_dir) || {
  echo "Error: cannot find Typora themes directory."
  echo "Please open Typora -> Preferences -> Appearance -> Open Theme Folder"
  echo "Then re-run: THEMES_DIR=/your/path bash install.sh"
  exit 1
}

echo "Typora themes directory: $THEMES_DIR"

# --- Download latest release ---
echo "Downloading latest Bloom theme..."
URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep "browser_download_url.*$ZIP_NAME" | head -1 | cut -d'"' -f4)

if [ -z "$URL" ]; then
  echo "Error: could not find $ZIP_NAME in latest release."
  exit 1
fi

curl -fsSL -o "$TMP_DIR/$ZIP_NAME" "$URL"

# --- Extract and install ---
echo "Extracting..."
unzip -o -q "$TMP_DIR/$ZIP_NAME" -d "$TMP_DIR/out"

echo "Installing themes to $THEMES_DIR ..."
cp -f "$TMP_DIR/out"/bloom-*.css "$THEMES_DIR/" 2>/dev/null || true
cp -rf "$TMP_DIR/out/bloom" "$THEMES_DIR/" 2>/dev/null || true

echo ""
echo "Done! Open Typora and pick a Bloom theme from the Themes menu."
