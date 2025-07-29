#!/run/current-system/sw/bin/bash
WALLPAPER_DIR="$HOME/.config/hypr/wallpaper"
mkdir -p "$WALLPAPER_DIR"
WALLPAPER_FILE=$(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | head -1)
if [ -z "$WALLPAPER_FILE" ]; then
    echo "no wallpaper found in $WALLPAPER_DIR"
    exit 1
fi
sed -i "s|preload = ~/.config/hypr/wallpaper/.*|preload = $WALLPAPER_FILE|g" "$HOME/.config/hypr/hyprpaper.conf"
sed -i "s|wallpaper = DP-1,~/.config/hypr/wallpaper/.*|wallpaper = DP-1,$WALLPAPER_FILE|g" "$HOME/.config/hypr/hyprpaper.conf"
sed -i "s|path = ~/.config/hypr/wallpaper/.*|path = $WALLPAPER_FILE|g" "$HOME/.config/hypr/hyprlock.conf"
pkill hyprpaper 2>/dev/null
sleep 0.5
hyprpaper &
echo "both desktop and lock screen now use: $(basename "$WALLPAPER_FILE")"
