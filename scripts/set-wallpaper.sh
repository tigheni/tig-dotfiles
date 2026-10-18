#!/bin/sh
# Set the wallpaper on every monitor and recolour the desktop from it.
#   set-wallpaper.sh        reuse the remembered wallpaper (login)
#   set-wallpaper.sh FILE   switch to FILE and remember it (dashboard picker)
# Without a remembered choice, the first image in ~/.config/hypr/wallpaper
# is used. Only runtime files are written; tracked configs stay untouched.

set -eu

default_dir="$HOME/.config/hypr/wallpaper"
state_file="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
log_file="${XDG_CACHE_HOME:-$HOME/.cache}/set-wallpaper.log"

mkdir -p "$(dirname "$log_file")" "$(dirname "$state_file")"
# Keep only the latest run's log.
: >"$log_file"
log() { printf '%s %s\n' "$(date +%T)" "$*" >>"$log_file"; }

if [ $# -gt 0 ]; then
    if [ ! -f "$1" ]; then
        echo "no such file: $1" >&2
        exit 1
    fi
    wallpaper=$(realpath "$1")
    printf '%s\n' "$wallpaper" >"$state_file"
elif [ -r "$state_file" ] && [ -f "$(cat "$state_file")" ]; then
    wallpaper=$(cat "$state_file")
else
    wallpaper=$(find "$default_dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' \
        -o -iname '*.jpeg' -o -iname '*.webp' \) | sort | head -n1)
fi
if [ -z "$wallpaper" ]; then
    log "no wallpaper found in $default_dir"
    echo "no wallpaper found in $default_dir" >&2
    exit 1
fi
log "wallpaper: $wallpaper"

# hyprlock reads the wallpaper through this link.
ln -sfn "$wallpaper" "$runtime_dir/wallpaper"

# Regenerate the colour tokens; config/matugen/config.toml's post_hook then
# reloads Waybar and mako. Quickshell watches the tokens file itself.
if command -v matugen >/dev/null; then
    matugen image --source-color-index 0 "$wallpaper" >>"$log_file" 2>&1 || log "matugen failed"
fi

if ! pgrep -x hyprpaper >/dev/null; then
    printf 'splash = false\nipc = on\n' >"$runtime_dir/hyprpaper.conf"
    # Own session, so it outlives whatever started this script.
    setsid -f hyprpaper -c "$runtime_dir/hyprpaper.conf" >>"$log_file" 2>&1
    log "started hyprpaper"
fi

# Wait until hyprpaper answers IPC (it takes a moment at login).
i=0
until hyprctl hyprpaper listactive >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -ge 25 ]; then
        log "hyprpaper did not respond"
        exit 1
    fi
    sleep 0.2
done

for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
    hyprctl hyprpaper wallpaper "$monitor,$wallpaper" >>"$log_file" 2>&1 || log "failed on $monitor"
done

log "done"
echo "wallpaper and lock screen now use: $(basename "$wallpaper")"
