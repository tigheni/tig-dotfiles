#!/bin/sh
# Toggle between "all windows stacked fullscreen" (one group) and split tiling
# for the current workspace.

active=$(hyprctl activewindow -j)
addr=$(printf '%s' "$active" | jq -r '.address')
[ "$addr" = "null" ] && exit 0

if [ "$(printf '%s' "$active" | jq '.grouped | length')" -gt 0 ]; then
  # Grouped -> split the windows side by side.
  hyprctl dispatch togglegroup
  exit 0
fi

# Split -> merge every tiled window on this workspace into one group.
ws=$(printf '%s' "$active" | jq '.workspace.id')
hyprctl dispatch togglegroup

ungrouped() {
  hyprctl clients -j | jq -r --argjson ws "$ws" \
    '.[] | select(.workspace.id == $ws and .floating == false and (.grouped | length) == 0) | .address'
}

# Each pass pulls every adjacent window into the group; repeat until done.
tries=0
while [ -n "$(ungrouped)" ] && [ "$tries" -lt 10 ]; do
  for w in $(ungrouped); do
    for dir in l r u d; do
      hyprctl --batch "dispatch focuswindow address:$w ; dispatch moveintogroup $dir" >/dev/null
      hyprctl clients -j | jq -e --arg w "$w" \
        '.[] | select(.address == $w) | (.grouped | length) > 0' >/dev/null && break
    done
  done
  tries=$((tries + 1))
done

hyprctl dispatch focuswindow "address:$addr" >/dev/null
