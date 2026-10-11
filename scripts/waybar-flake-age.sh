#!/bin/sh
# Waybar custom/flake-age: show how old the pinned nixpkgs is once it passes
# the threshold, and hide the module (empty text) while it is fresh.

threshold_days=14
lock="${DOTFILES_DIR:?DOTFILES_DIR is not set}/flake.lock"

modified=$(jq -r '.nodes[.nodes.root.inputs.nixpkgs].locked.lastModified // empty' "$lock" 2>/dev/null)
[ -n "$modified" ] || exit 0

days=$((($(date +%s) - modified) / 86400))
[ "$days" -ge "$threshold_days" ] || {
    echo '{"text":""}'
    exit 0
}

printf '{"text":"󱄅 %sd","class":"stale","tooltip":"nixpkgs pinned %s days ago\\nClick to update the flake and switch"}\n' "$days" "$days"
