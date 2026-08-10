#!/run/current-system/sw/bin/bash

set -euo pipefail

# Automatic night light script
# Warm temperature (2800K) from 8pm to 7am
# Normal temperature (6500K) from 7am to 8pm

CURRENT_HOUR=$(date +%H)
WARM_TEMP=2700
NORMAL_TEMP=6500

# Hyprland starts this script at login, often before wl-gammarelay-rs has
# registered its D-Bus name. Wait for the relay instead of silently failing.
for _ in {1..30}; do
    if busctl --user list | awk '$1 == "rs.wl-gammarelay" { found=1 } END { exit !found }'; then
        break
    fi
    sleep 1
done

if ! busctl --user list | awk '$1 == "rs.wl-gammarelay" { found=1 } END { exit !found }'; then
    echo "wl-gammarelay-rs is not available after 30 seconds" >&2
    exit 1
fi


# Check if current time is between 8pm (20:00) and 7am (07:00)
if [ "$CURRENT_HOUR" -ge 20 ] || [ "$CURRENT_HOUR" -lt 7 ]; then
    # Night time - use warm temperature
    busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q $WARM_TEMP
    echo "🌙 Night mode activated (${WARM_TEMP}K) at $(date '+%H:%M')"
else
    # Day time - use normal temperature
    busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q $NORMAL_TEMP
    echo "☀️ Day mode activated (${NORMAL_TEMP}K) at $(date '+%H:%M')"
fi
