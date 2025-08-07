#!/run/current-system/sw/bin/bash
WALLPAPER_DIR="$HOME/.config/hypr/wallpaper"
mkdir -p "$WALLPAPER_DIR"
# Find the first wallpaper file in the directory (any image format)
WALLPAPER_FILE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.gif" \) | head -1)
if [ -z "$WALLPAPER_FILE" ]; then
    echo "no wallpaper found in $WALLPAPER_DIR"
    exit 1
fi

# Update hyprpaper.conf - replace any existing preload and wallpaper lines
sed -i "s|^preload = .*|preload = $WALLPAPER_FILE|g" "$HOME/.config/hypr/hyprpaper.conf"
sed -i "s|^wallpaper = DP-1,.*|wallpaper = DP-1,$WALLPAPER_FILE|g" "$HOME/.config/hypr/hyprpaper.conf"

# Update hyprlock.conf - replace any existing path line
sed -i "s|^.*path = .*|    path = $WALLPAPER_FILE|g" "$HOME/.config/hypr/hyprlock.conf"

pkill hyprpaper 2>/dev/null
sleep 0.5
hyprpaper &
echo "both desktop and lock screen now use: $(basename "$WALLPAPER_FILE")"
