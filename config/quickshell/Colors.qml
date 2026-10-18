pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The matugen palette, read from the same file Waybar uses, so the
// dashboard recolours itself whenever the wallpaper changes.
Singleton {
    id: root

    property color bg: "#101417"
    property color card: "#1c2024"
    property color cardHigh: "#262a2e"
    property color fg: "#e0e3e8"
    property color fgDim: "#c1c7ce"
    property color outline: "#8b9198"
    property color accent: "#95cdf7"
    property color warn: "#cec0e8"
    property color error: "#ffb4ab"
    readonly property string font: "JetBrainsMono Nerd Font"

    function parse(css) {
        const get = name => {
            const m = css.match(new RegExp("@define-color " + name + " (#[0-9a-fA-F]{6});"));
            return m ? m[1] : null;
        };
        bg = get("surface") ?? bg;
        card = get("surface_container") ?? card;
        cardHigh = get("surface_container_high") ?? cardHigh;
        fg = get("on_surface") ?? fg;
        fgDim = get("on_surface_variant") ?? fgDim;
        outline = get("outline") ?? outline;
        accent = get("primary") ?? accent;
        warn = get("tertiary") ?? warn;
        error = get("error") ?? error;
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/waybar/tokens/colors.css"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }
}
