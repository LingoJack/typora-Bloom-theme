#!/usr/bin/env bash
set -euo pipefail

REPO="LingoJack/typora-Bloom-theme"
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

# --- Download latest release that contains the zip ---
echo "Downloading latest Bloom theme..."
URL=""

# Try latest release first, then fall back to older releases
PAGE=1
while [ -z "$URL" ] && [ "$PAGE" -le 5 ]; do
  if [ "$PAGE" -eq 1 ]; then
    # First try the "latest" endpoint (most recent non-draft, non-prerelease)
    RELEASES_JSON=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null)
    URL=$(echo "$RELEASES_JSON" | grep "browser_download_url.*$ZIP_NAME" | head -1 | cut -d'"' -f4)
    if [ -n "$URL" ]; then break; fi
    echo "  (latest release has no $ZIP_NAME, searching older releases...)"
  fi

  # Fall back to paginated list of all releases
  RELEASES_JSON=$(curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=10&page=$PAGE" 2>/dev/null)
  URL=$(echo "$RELEASES_JSON" | grep "browser_download_url.*$ZIP_NAME" | head -1 | cut -d'"' -f4)
  if [ -n "$URL" ]; then break; fi

  echo "  (page $PAGE: no $ZIP_NAME found, trying older releases...)"
  PAGE=$((PAGE + 1))
done

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
