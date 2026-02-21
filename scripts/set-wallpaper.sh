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

# Keep config files in sync for restart/reboot cases.
sed -i "s|^preload = .*|preload = $WALLPAPER_FILE|g" "$HYPRPAPER_CONF"
sed -i "s|^wallpaper = .*|wallpaper = ,$WALLPAPER_FILE|g" "$HYPRPAPER_CONF"
sed -i "s|^.*path = .*|    path = $WALLPAPER_FILE|g" "$HYPRLOCK_CONF"

# Ensure hyprpaper is running before sending IPC commands.
if ! pgrep -x hyprpaper >/dev/null; then
    hyprpaper &
    sleep 0.8
fi

# Apply wallpaper to every currently connected monitor via IPC.
hyprctl hyprpaper unload all >/dev/null 2>&1 || true
hyprctl hyprpaper preload "$WALLPAPER_FILE" >/dev/null

while read -r monitor; do
    [ -n "$monitor" ] || continue
    hyprctl hyprpaper wallpaper "$monitor,$WALLPAPER_FILE" >/dev/null
done < <(hyprctl monitors | awk '/^Monitor / {print $2}')

echo "desktop and lock screen now use: $(basename "$WALLPAPER_FILE")"
