#!/usr/bin/env bash

# Simple script to cycle through audio outputs using wpctl

# Get current default sink ID (the one with *)
current_sink=$(wpctl status | sed -n '/├─ Sinks:/,/├─ Sources:/p' | grep -E "^\s*[│]\s*[*]\s*[0-9]+\." | sed 's/.*\*[[:space:]]*\([0-9]\+\)\..*/\1/')

# Get all available sink IDs
all_sinks=($(wpctl status | sed -n '/├─ Sinks:/,/├─ Sources:/p' | grep -E "^\s*[│]\s*[*]?\s*[0-9]+\." | sed 's/.*[│][[:space:]]*\*\?[[:space:]]*\([0-9]\+\)\..*/\1/'))

echo "Current sink: $current_sink"
echo "All sinks: ${all_sinks[@]}"

# Find next sink to switch to
next_sink=""
for i in "${!all_sinks[@]}"; do
    if [[ "${all_sinks[$i]}" == "$current_sink" ]]; then
        # Get next sink, or wrap to first if at end
        next_index=$(( (i + 1) % ${#all_sinks[@]} ))
        next_sink="${all_sinks[$next_index]}"
        break
    fi
done

# If we couldn't find current sink or determine next, just use first available
if [[ -z "$next_sink" ]]; then
    next_sink="${all_sinks[0]}"
fi

echo "Next sink: $next_sink"

# Switch to next sink
if [[ -n "$next_sink" ]]; then
    wpctl set-default "$next_sink"

    # Get sink name for notification
    sink_name=$(wpctl status | awk "/^[[:space:]]*$next_sink\./ {gsub(/^[[:space:]]*[0-9]+\.[[:space:]]*/, \"\"); gsub(/[[:space:]]*\\[.*\\]/, \"\"); print}")

    # Send notification
    if command -v notify-send >/dev/null; then
        notify-send "Audio Output" "Switched to: $sink_name" -t 2000
    fi

    echo "Switched to audio output: $sink_name (ID: $next_sink)"
else
    echo "No audio outputs found to switch to"
fi
