#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/.config/hypr/wallpaper"
HYPR_DIR="$HOME/.config/hypr"
HYPRPAPER_CONF="$HYPR_DIR/hyprpaper.conf"
HYPRLOCK_CONF="$HYPR_DIR/hyprlock.conf"
HYPRLAND_CONF="$HYPR_DIR/hyprland.conf"
LOGFILE="${XDG_CACHE_HOME:-$HOME/.cache}/set-wallpaper.log"
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$(dirname "$LOGFILE")"

log() {
    printf '%s %s\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >> "$LOGFILE"
}

log "set-wallpaper: starting"

# Find the first wallpaper file in the directory (any image format)
WALLPAPER_FILE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.gif" \) | head -1)
if [ -z "$WALLPAPER_FILE" ]; then
    log "no wallpaper found in $WALLPAPER_DIR"
    echo "no wallpaper found in $WALLPAPER_DIR"
    exit 1
fi
log "found wallpaper: $WALLPAPER_FILE"

# Detect monitors from config as an initial fallback.
CONFIG_MONITORS=""
if [ -f "$HYPRLAND_CONF" ]; then
    CONFIG_MONITORS=$(awk -F',' '/^\s*monitor\s*=/{gsub(/^\s*monitor\s*=\s*/, "", $1); gsub(/\s+$/, "", $1); if ($1 != "") print $1}' "$HYPRLAND_CONF")
    log "configured monitors from hyprland.conf: $CONFIG_MONITORS"
fi

# Build a baseline hyprpaper.conf.
# We keep only preload/runtime options here and apply final monitor mappings via hyprctl
# after hyprpaper starts and real outputs are available.
{
    echo "preload = $WALLPAPER_FILE"
    echo "splash = false"
    echo "ipc = on"
} > "$HYPRPAPER_CONF"

# Update hyprlock.conf - replace any existing path line or add one
if [ -f "$HYPRLOCK_CONF" ]; then
    if grep -q "path =" "$HYPRLOCK_CONF"; then
        sed -i "s|^.*path = .*|    path = $WALLPAPER_FILE|g" "$HYPRLOCK_CONF"
        log "updated existing hyprlock.conf path"
    else
        printf "    path = %s\n" "$WALLPAPER_FILE" >> "$HYPRLOCK_CONF"
        log "appended path to hyprlock.conf"
    fi
else
    printf "# hyprlock wallpaper path\n    path = %s\n" "$WALLPAPER_FILE" > "$HYPRLOCK_CONF"
    log "created hyprlock.conf with path"
fi

if command -v hyprpaper >/dev/null 2>&1; then
    if pgrep -x hyprpaper >/dev/null 2>&1; then
        log "hyprpaper already running; will reuse existing instance"
    else
        nohup hyprpaper >>"$LOGFILE" 2>&1 &
        log "started hyprpaper (nohup)"
    fi
    # wait for hyprpaper socket to appear (hypr creates per-instance dirs)
    HP_DIR=""
    for _ in $(seq 1 20); do
        HP_DIR=$(ls -1d /run/user/$(id -u)/hypr/* 2>/dev/null | head -1 || true)
        if [ -n "$HP_DIR" ] && [ -e "$HP_DIR/.hyprpaper.sock" ]; then
            log "found hyprpaper socket in $HP_DIR"
            break
        fi
        sleep 0.2
    done
else
    log "hyprpaper not found in PATH"
fi

# Try to apply wallpaper targets through hyprpaper IPC with retries.
# This avoids stale/wrong monitor names at startup.
MONITORS=""
if command -v hyprctl >/dev/null 2>&1; then
    for _ in $(seq 1 20); do
        # Try to extract monitor name robustly from hyprctl output
        MONITORS=$(hyprctl monitors 2>/dev/null | awk '/^Monitor/ { if (match($0, /: ([^ ]+)/)) { print substr($0, RSTART+2, RLENGTH-2) } else { print $2 } }')
        [ -n "$MONITORS" ] && break
        sleep 0.2
    done

    # Fallback to configured monitors, then DP-1 if runtime list is still empty.
    if [ -z "$MONITORS" ]; then
        MONITORS="$CONFIG_MONITORS"
        log "hyprctl returned no monitors, falling back to config: $MONITORS"
    fi
    if [ -z "$MONITORS" ]; then
        MONITORS="DP-1"
        log "no monitors found; using fallback: $MONITORS"
    fi

    # Ensure image is loaded in hyprpaper and mapped to each detected output.
    hyprctl hyprpaper preload "$WALLPAPER_FILE" >>"$LOGFILE" 2>&1 || log "hyprctl preload failed"
    echo "$MONITORS" | awk '!seen[$0]++' | while IFS= read -r MONITOR; do
        if [ -n "$MONITOR" ]; then
            hyprctl hyprpaper wallpaper "$MONITOR,$WALLPAPER_FILE" >>"$LOGFILE" 2>&1 || log "failed to set wallpaper for $MONITOR"
            log "set wallpaper for monitor: $MONITOR"
        fi
    done
fi

echo "both desktop and lock screen now use: $(basename "$WALLPAPER_FILE")"
log "completed: $(basename "$WALLPAPER_FILE")"
