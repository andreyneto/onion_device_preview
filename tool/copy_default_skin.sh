#!/usr/bin/env bash
# Copies the OnionOS default skin (theme "Silky") from the sibling Onion/
# firmware checkout into assets/default_skin/, so the package always has
# a fallback to render when a theme zip is missing an asset (mirrors the
# firmware's own fallback chain, see Onion/src/common/theme/load.h).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ONION_APP_DIR="$PACKAGE_DIR/../Onion/static/build/miyoo/app"
ONION_RES_DIR="$PACKAGE_DIR/../Onion/static/build/.tmp_update/res"
DEST_DIR="$PACKAGE_DIR/assets/default_skin"

if [[ ! -d "$ONION_APP_DIR" ]]; then
  echo "error: $ONION_APP_DIR not found — is ../Onion checked out next to this package?" >&2
  exit 1
fi

rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR/skin/extra" "$DEST_DIR/fonts" "$DEST_DIR/sound"

cp "$ONION_APP_DIR/config.json" "$DEST_DIR/config.json"
cp "$ONION_APP_DIR"/skin/*.png "$DEST_DIR/skin/"

# Default theme sounds (bgm loop + navigation blip), same fallback role
# as the skin assets. See T5.6.
mkdir -p "$DEST_DIR/sound"
cp "$ONION_APP_DIR/sound/bgm.mp3" "$DEST_DIR/sound/"
cp "$ONION_APP_DIR/sound/change.wav" "$DEST_DIR/sound/"

# The bundled "Default" icon pack — the device serves these from
# /mnt/SDCARD/Icons/<pack>/ and a theme's own icons/ dir replaces them
# (installTheme.h:205-210 applies the theme's pack with reset_default,
# i.e. per-icon fallback to Default). Layout mirrors apply_icons.h:104-130:
# <pack>/<name>.png for systems, <pack>/app/<name>.png for apps.
# Only the ones the mock references.
ICONS_DIR="$PACKAGE_DIR/../Onion/static/build/Icons/Default"
mkdir -p "$DEST_DIR/icons/app"
for icon in search gba sfc ps md gb gbc neogeo arcade; do
  cp "$ICONS_DIR/$icon.png" "$DEST_DIR/icons/"
done
for icon in retroarch commander battery_monitor ereader tweaks gameswitcher; do
  cp "$ICONS_DIR/app/$icon.png" "$DEST_DIR/icons/app/"
done

# System-resource fallback assets the firmware serves from
# /mnt/SDCARD/.tmp_update/res when a theme's skin/extra/ doesn't have them.
cp "$ONION_RES_DIR/toggle-on.png" "$DEST_DIR/skin/extra/toggle-on.png"
cp "$ONION_RES_DIR/toggle-off.png" "$DEST_DIR/skin/extra/toggle-off.png"

# Default charging animation (chargingState.c falls back to its res/
# frames when the theme ships none — the purple glow battery loop).
cp "$PACKAGE_DIR/../Onion/src/chargingState/res/chargingState"*.png "$DEST_DIR/skin/extra/"
cp "$PACKAGE_DIR/../Onion/src/chargingState/res/chargingState.json" "$DEST_DIR/skin/extra/"

# Game Switcher fallbacks, same extra/ → app res/ rule (load.h:57-60):
# the button legend, the brightness slider frames (lum0-10) and the
# white-bordered arrows of the game name bar. NOTE: gs-top-bar and
# gs-bottom-bar are deliberately NOT copied — the switcher only draws its
# custom bars when the *theme* ships them (gameSwitcher.c:71-75), so they
# must stay unresolvable in the default skin.
GS_RES_DIR="$PACKAGE_DIR/../Onion/src/gameSwitcher/res"
cp "$GS_RES_DIR/gs-legend.png" "$DEST_DIR/skin/extra/"
cp "$GS_RES_DIR"/lum*.png "$DEST_DIR/skin/extra/"
cp "$GS_RES_DIR/arrowLeft.png" "$DEST_DIR/skin/extra/"
cp "$GS_RES_DIR/arrowRight.png" "$DEST_DIR/skin/extra/"

# System fonts (non-CJK, non-.ttc — Flutter's font loader doesn't support
# TrueType Collections). See plan.md §3/F3.
cp "$ONION_APP_DIR/Exo-2-Bold-Italic.ttf" "$DEST_DIR/fonts/"
cp "$ONION_APP_DIR/BPreplayBold.otf" "$DEST_DIR/fonts/"
cp "$ONION_APP_DIR/Helvetica-Neue-2.ttf" "$DEST_DIR/fonts/"

rm -f "$DEST_DIR/.gitkeep"

echo "Copied default skin to $DEST_DIR:"
find "$DEST_DIR" -type f | wc -l | xargs echo "  files:"
du -sh "$DEST_DIR" | awk '{print "  size:  " $1}'
