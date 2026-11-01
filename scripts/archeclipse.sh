#!/bin/sh
# Start or talk to the ArchEclipse shell (config/quickshell/archeclipse).
#   archeclipse.sh start         run it (Hyprland autostart)
#   archeclipse.sh restart       stop the running instance and start a fresh one
#   archeclipse.sh toggle-bar    hide/show the bar on the focused monitor (Super+W)
#   archeclipse.sh right-panel   open/close the right panel on the focused monitor (Super+D)
#   archeclipse.sh search        open/close the launcher on the focused monitor (tap Super)
#   archeclipse.sh clipboard     open/close the clipboard history popup (Super+Shift+V)
#   archeclipse.sh record MODE   start/stop recording, MODE now|area (Super+Print, Super+Shift+Print)
#   archeclipse.sh dismiss       hide the newest notification popup (Super+Q)
#   archeclipse.sh tour          reopen the welcome tour
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
restart)
    # Called from inside the shell (Custom scripts), so it must outlive the kill.
    qs -p "$config" kill >/dev/null 2>&1 || true
    exec setsid -f qs -p "$config" >/dev/null 2>&1
    ;;
toggle-bar)
    exec qs -p "$config" ipc call bar toggleBar "$(focused_monitor)"
    ;;
right-panel)
    exec qs -p "$config" ipc call bar toggleRightPanel "$(focused_monitor)"
    ;;
search)
    exec qs -p "$config" ipc call bar toggleSearch "$(focused_monitor)"
    ;;
clipboard)
    exec qs -p "$config" ipc call clipboardPopup toggle
    ;;
record)
    exec qs -p "$config" ipc call bar screenrecord "${2:-now}" "$(focused_monitor)"
    ;;
dismiss)
    exec qs -p "$config" ipc call bar dismissNotification
    ;;
tour)
    exec qs -p "$config" ipc call welcome open
    ;;
*)
    echo "usage: archeclipse.sh start|restart|toggle-bar|right-panel|search|clipboard|record now|area|dismiss|tour" >&2
    exit 2
    ;;
esac
