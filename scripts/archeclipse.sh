#!/bin/sh
# Start or talk to the ArchEclipse shell (config/quickshell/archeclipse).
#   archeclipse.sh start         run it (Hyprland autostart)
#   archeclipse.sh toggle-bar    hide/show the bar on the focused monitor (Super+W)
#   archeclipse.sh right-panel   open/close the right panel on the focused monitor (Super+D)
#   archeclipse.sh dismiss       hide the newest notification popup (Super+Q)
# It runs by path, so every call names the config directory explicitly.

set -eu

config="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/archeclipse"

focused_monitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
}

case "${1:-}" in
start)
    exec qs -p "$config"
    ;;
toggle-bar)
    exec qs -p "$config" ipc call bar toggleBar "$(focused_monitor)"
    ;;
right-panel)
    exec qs -p "$config" ipc call bar toggleRightPanel "$(focused_monitor)"
    ;;
dismiss)
    exec qs -p "$config" ipc call bar dismissNotification
    ;;
*)
    echo "usage: archeclipse.sh start|toggle-bar|right-panel|dismiss" >&2
    exit 2
    ;;
esac
