#!/run/current-system/sw/bin/bash
WALLPAPER_DIR="$HOME/.config/hypr/wallpaper"
HYPR_DIR="$HOME/.config/hypr"
HYPRPAPER_CONF="$HYPR_DIR/hyprpaper.conf"
HYPRLOCK_CONF="$HYPR_DIR/hyprlock.conf"
HYPRLAND_CONF="$HYPR_DIR/hyprland.conf"
mkdir -p "$WALLPAPER_DIR"

# Find the first wallpaper file in the directory (any image format)
WALLPAPER_FILE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.gif" \) | head -1)
if [ -z "$WALLPAPER_FILE" ]; then
    echo "no wallpaper found in $WALLPAPER_DIR"
    exit 1
fi

# Detect monitors from config as an initial fallback.
CONFIG_MONITORS=""
if [ -f "$HYPRLAND_CONF" ]; then
    CONFIG_MONITORS=$(awk -F',' '/^\s*monitor\s*=/{gsub(/^\s*monitor\s*=\s*/, "", $1); gsub(/\s+$/, "", $1); if ($1 != "") print $1}' "$HYPRLAND_CONF")
fi

# Build a baseline hyprpaper.conf.
# We keep only preload/runtime options here and apply final monitor mappings via hyprctl
# after hyprpaper starts and real outputs are available.
{
    echo "preload = $WALLPAPER_FILE"
    echo "splash = false"
    echo "ipc = on"
} > "$HYPRPAPER_CONF"

# Update hyprlock.conf - replace any existing path line
sed -i "s|^.*path = .*|    path = $WALLPAPER_FILE|g" "$HYPRLOCK_CONF"

pkill hyprpaper 2>/dev/null
sleep 0.5
hyprpaper &

# Try to apply wallpaper targets through hyprpaper IPC with retries.
# This avoids stale/wrong monitor names at startup.
MONITORS=""
if command -v hyprctl >/dev/null 2>&1; then
    for _ in $(seq 1 20); do
        MONITORS=$(hyprctl monitors 2>/dev/null | awk '/^Monitor / {print $2}')
        [ -n "$MONITORS" ] && break
        sleep 0.2
    done

    # Fallback to configured monitors, then DP-1 if runtime list is still empty.
    if [ -z "$MONITORS" ]; then
        MONITORS="$CONFIG_MONITORS"
    fi
    if [ -z "$MONITORS" ]; then
        MONITORS="DP-1"
    fi

    # Ensure image is loaded in hyprpaper and mapped to each detected output.
    hyprctl hyprpaper preload "$WALLPAPER_FILE" >/dev/null 2>&1
    echo "$MONITORS" | awk '!seen[$0]++' | while IFS= read -r MONITOR; do
        [ -n "$MONITOR" ] && hyprctl hyprpaper wallpaper "$MONITOR,$WALLPAPER_FILE" >/dev/null 2>&1
    done
fi

echo "both desktop and lock screen now use: $(basename "$WALLPAPER_FILE")"
