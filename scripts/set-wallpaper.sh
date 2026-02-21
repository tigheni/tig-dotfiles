#!/run/current-system/sw/bin/bash
set -euo pipefail

WALLPAPER_DIR="$HOME/.config/hypr/wallpaper"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"

mkdir -p "$WALLPAPER_DIR"

# Find the first wallpaper file in the directory (any image format)
WALLPAPER_FILE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.gif" \) | head -1)
if [ -z "$WALLPAPER_FILE" ]; then
    echo "no wallpaper found in $WALLPAPER_DIR"
    exit 1
fi

