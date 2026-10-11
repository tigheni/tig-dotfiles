#!/bin/sh
# Waybar custom/gpu-usage: report amdgpu busy % and VRAM usage as JSON.
# The iGPU only has a small reserved VRAM slice, so show MiB rather than a
# percentage that always reads close to full.

for dev in /sys/class/drm/card*/device; do
    [ -r "$dev/gpu_busy_percent" ] || continue
    busy=$(cat "$dev/gpu_busy_percent")
    used_mb=$(($(cat "$dev/mem_info_vram_used") / 1048576))
    total_mb=$(($(cat "$dev/mem_info_vram_total") / 1048576))
    printf '{"text":"<span color=\\"#df6124\\">gpu</span> %s%% <span color=\\"#df6124\\">vram</span> %sM","tooltip":"GPU busy %s%%\\nVRAM %s/%s MiB (shared with system RAM)"}\n' \
        "$busy" "$used_mb" "$busy" "$used_mb" "$total_mb"
    exit 0
done

echo '{"text":"","tooltip":"No GPU found"}'
