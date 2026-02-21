#!/run/current-system/sw/bin/bash
WALLPAPER_DIR="$HOME/.config/hypr/wallpaper"
<<<<<<< HEAD
HYPR_DIR="$HOME/.config/hypr"
HYPRPAPER_CONF="$HYPR_DIR/hyprpaper.conf"
HYPRLOCK_CONF="$HYPR_DIR/hyprlock.conf"
HYPRLAND_CONF="$HYPR_DIR/hyprland.conf"
=======
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
>>>>>>> 075174e (fix: correct wallpaper directory path and enhance hyprpaper configuration)
mkdir -p "$WALLPAPER_DIR"

# Find the first wallpaper file in the directory (any image format)
WALLPAPER_FILE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.gif" \) | head -1)
if [ -z "$WALLPAPER_FILE" ]; then
    echo "no wallpaper found in $WALLPAPER_DIR"
    exit 1
fi

<<<<<<< HEAD
# Detect monitors with fallbacks:
# 1) hyprctl runtime outputs
# 2) monitor entries in hyprland.conf
# 3) hard fallback DP-1
MONITORS=""
if command -v hyprctl >/dev/null 2>&1; then
    MONITORS=$(hyprctl monitors 2>/dev/null | awk '/^Monitor / {print $2}')
fi

if [ -z "$MONITORS" ] && [ -f "$HYPRLAND_CONF" ]; then
    MONITORS=$(awk -F',' '/^\s*monitor\s*=/{gsub(/^\s*monitor\s*=\s*/, "", $1); gsub(/\s+$/, "", $1); if ($1 != "") print $1}' "$HYPRLAND_CONF")
fi

if [ -z "$MONITORS" ]; then
    MONITORS="DP-1"
fi

# Build hyprpaper.conf with one wallpaper target per detected monitor.
{
    echo "preload = $WALLPAPER_FILE"

    echo "$MONITORS" | awk '!seen[$0]++' | while IFS= read -r MONITOR; do
        [ -n "$MONITOR" ] && echo "wallpaper = $MONITOR,$WALLPAPER_FILE"
    done
=======
# Update hyprpaper.conf - replace any existing preload and wallpaper lines
sed -i "s|^preload = .*|preload = $WALLPAPER_FILE|g" "$HOME/.config/hypr/hyprpaper.conf"
sed -i "s|^wallpaper = ,.*|wallpaper = ,$WALLPAPER_FILE|g" "$HOME/.config/hypr/hyprpaper.conf"
# Build hyprpaper.conf with currently connected monitor names.
# Fallback to monitor-agnostic syntax when monitor detection is unavailable.
{
    echo "preload = $WALLPAPER_FILE"

    MONITORS=$(hyprctl monitors 2>/dev/null | awk '/^Monitor / {print $2}')
    if [ -n "$MONITORS" ]; then
        while IFS= read -r MONITOR; do
            [ -n "$MONITOR" ] && echo "wallpaper = $MONITOR,$WALLPAPER_FILE"
        done <<< "$MONITORS"
    else
        echo "wallpaper = ,$WALLPAPER_FILE"
    fi
>>>>>>> 075174e (fix: correct wallpaper directory path and enhance hyprpaper configuration)

    echo "splash = false"
    echo "ipc = on"
} > "$HYPRPAPER_CONF"

# Update hyprlock.conf - replace any existing path line
sed -i "s|^.*path = .*|    path = $WALLPAPER_FILE|g" "$HYPRLOCK_CONF"

pkill hyprpaper 2>/dev/null
sleep 0.5
hyprpaper &
echo "both desktop and lock screen now use: $(basename "$WALLPAPER_FILE")"