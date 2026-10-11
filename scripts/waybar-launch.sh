#!/bin/sh
# Pango markup in the Waybar config cannot read CSS colours, so swap the
# default colours in the tracked config for the matugen palette, write the
# result to $XDG_RUNTIME_DIR and run Waybar
# from that copy. The tracked config still works on its own with plain `waybar`.
# `waybar-launch.sh render` only refreshes the runtime config
# (used by matugen's post_hook before reloading Waybar).

set -eu

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
colors="$config_dir/tokens/colors.css"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar"
runtime_config="$runtime_dir/config.jsonc"

color() {
    sed -n "s/^@define-color $1 \(#[0-9A-Fa-f]\{6\}\);.*/\1/p" "$colors" | head -n 1
}

render() {
    mkdir -p "$runtime_dir"
    primary=$(color primary)
    secondary=$(color secondary)
    tertiary=$(color tertiary)
    outline=$(color outline)
    sed \
        -e "s/#df6124/${primary:-#df6124}/g" \
        -e "s/#ffcc66/${secondary:-#ffcc66}/g" \
        -e "s/#ff6699/${tertiary:-#ff6699}/g" \
        -e "s/#616367/${outline:-#616367}/g" \
        "$config_dir/config.jsonc" >"$runtime_config.tmp"
    mv "$runtime_config.tmp" "$runtime_config"
}

render

if [ "${1:-}" = "render" ]; then
    exit 0
fi

pkill -x '\.?waybar(-wrapped)?' || true
exec waybar -c "$runtime_config" -s "$config_dir/style.css"
