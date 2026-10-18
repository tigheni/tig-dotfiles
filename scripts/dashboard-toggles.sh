#!/bin/sh
# Quick toggles for the Quickshell dashboard.
#   dashboard-toggles.sh status         JSON with the state of every toggle
#   dashboard-toggles.sh toggle NAME    flip one: vpn bluetooth night mic awake dnd

warm=2700
normal=6500

vpn_on() { mullvad status 2>/dev/null | head -n1 | grep -q '^Connected'; }
bt_on() { bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; }
temp() { busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Temperature 2>/dev/null | cut -d' ' -f2; }
night_on() { [ "$(temp)" -lt "$normal" ] 2>/dev/null; }
mic_on() { ! wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED; }
# "Stay awake" means hypridle is not running: no dimming, locking or suspend.
awake_on() { ! pgrep -x hypridle >/dev/null; }
dnd_on() { makoctl mode 2>/dev/null | grep -qx do-not-disturb; }

flag() { if "$1"; then echo true; else echo false; fi; }

case ${1:-status} in
status)
    printf '{"vpn":%s,"bluetooth":%s,"night":%s,"mic":%s,"awake":%s,"dnd":%s}\n' \
        "$(flag vpn_on)" "$(flag bt_on)" "$(flag night_on)" "$(flag mic_on)" "$(flag awake_on)" "$(flag dnd_on)"
    ;;
toggle)
    case $2 in
    vpn) if vpn_on; then mullvad disconnect; else mullvad connect; fi ;;
    bluetooth) if bt_on; then bluetoothctl power off; else bluetoothctl power on; fi ;;
    night)
        if night_on; then t=$normal; else t=$warm; fi
        busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q "$t"
        ;;
    mic) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
    awake) if awake_on; then hyprctl dispatch exec hypridle; else pkill -x hypridle; fi ;;
    dnd) makoctl mode -t do-not-disturb ;;
    *)
        echo "unknown toggle: $2" >&2
        exit 1
        ;;
    esac >/dev/null
    ;;
*)
    echo "usage: $0 status | toggle vpn|bluetooth|night|mic|awake|dnd" >&2
    exit 1
    ;;
esac
