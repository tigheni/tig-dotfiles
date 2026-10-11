#!/bin/sh
# Swap the default colours in the tracked mako config for the matugen palette,
# write the result to $XDG_RUNTIME_DIR and run mako from that copy. The tracked
# config still works on its own with plain `mako`.
# `mako-launch.sh render` only refreshes the runtime config and reloads a
# running mako (used by matugen's post_hook).

set -eu

config="${XDG_CONFIG_HOME:-$HOME/.config}/mako/config"
colors="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/tokens/colors.css"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/mako"
runtime_config="$runtime_dir/config"

color() {
    [ -r "$colors" ] || return 0
    sed -n "s/^@define-color $1 \(#[0-9A-Fa-f]\{6\}\);.*/\1/p" "$colors" | head -n 1
}

render() {
    mkdir -p "$runtime_dir"
    surface=$(color surface_container_high)
    on_surface=$(color on_surface)
    on_surface_variant=$(color on_surface_variant)
    outline=$(color outline)
    error=$(color error)
    sed \
        -e "s/#24273a/${surface:-#24273a}/g" \
        -e "s/#cdd6f4/${on_surface:-#cdd6f4}/g" \
        -e "s/#a6adc8/${on_surface_variant:-#a6adc8}/g" \
        -e "s/#6c7086/${outline:-#6c7086}/g" \
        -e "s/#f38ba8/${error:-#f38ba8}/g" \
        "$config" >"$runtime_config.tmp"
    mv "$runtime_config.tmp" "$runtime_config"
}

render

if [ "${1:-}" = "render" ]; then
    makoctl reload 2>/dev/null || true
    exit 0
fi

# Nix wraps the binary, so the process is named .mako-wrapped.
pkill -x '\.?mako(-wrapped)?' || true
exec mako --config "$runtime_config"
