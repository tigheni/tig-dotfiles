#!/bin/sh
# Waybar custom/gpu-usage: report amdgpu busy % as JSON, with VRAM in the tooltip.

colors="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/tokens/colors.css"
accent=$(sed -n "s/^@define-color primary \(#[0-9A-Fa-f]\{6\}\);.*/\1/p" "$colors" 2>/dev/null)
accent=${accent:-#df6124}

for dev in /sys/class/drm/card*/device; do
    [ -r "$dev/gpu_busy_percent" ] || continue
    busy=$(cat "$dev/gpu_busy_percent")
    used_mb=$(($(cat "$dev/mem_info_vram_used") / 1048576))
    total_mb=$(($(cat "$dev/mem_info_vram_total") / 1048576))
    printf '{"text":"<span color=\\"%s\\">gpu</span> %s%%","tooltip":"GPU busy %s%%\\nVRAM %s/%s MiB (shared with system RAM)"}\n' \
        "$accent" "$busy" "$busy" "$used_mb" "$total_mb"
    exit 0
done

echo '{"text":"","tooltip":"No GPU found"}'
