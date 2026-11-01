#!/bin/sh
# Start or talk to the ArchEclipse shell (config/quickshell/archeclipse).
#   archeclipse.sh start        run it (Hyprland autostart)
#   archeclipse.sh toggle-bar   hide/show the bar on the focused monitor (Super+W)
#   archeclipse.sh dismiss      hide the newest notification popup (Super+Q)
# It runs by path: the Super+D dashboard owns ~/.config/quickshell/shell.qml,
# so `qs -c archeclipse` does not find it.

set -eu

config="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/archeclipse"

case "${1:-}" in
start)
    exec qs -p "$config"
    ;;
toggle-bar)
    monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
    exec qs -p "$config" ipc call bar toggleBar "$monitor"
    ;;
dismiss)
    exec qs -p "$config" ipc call bar dismissNotification
    ;;
*)
    echo "usage: archeclipse.sh start|toggle-bar|dismiss" >&2
    exit 2
    ;;
esac
