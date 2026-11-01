import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.theme
import qs.widgets.shared

// Key Binds widget — reads the live binds from `hyprctl binds -j` and
// renders each binding as key chips joined by "+", grouped by category.
Item {
    id: root
    property int widgetWidth: parent.width

    // keybinds shape (was get-keybinds.sh): { category: [{ description, keys: [] }] }
    property var keybinds: ({})
    property bool loading: true

    // Unified entrance fade (StackLayout builds tabs hidden): the whole page
    // fades in once, replacing the old per-row stagger.
    property real revealOpacity: 0
    property int totalBinds: 0
    Anim {
        id: revealFade
        target: root
        property: "revealOpacity"
        from: 0
        to: 1
        type: Anim.DefaultEffects
    }
    function recomputeOffsets() {
        let n = 0;
        for (const c of Object.keys(root.keybinds).sort())
            n += ((root.keybinds[c] || []).length);
        root.totalBinds = n;
    }
    function playReveal() {
        revealFade.restart();
    }
    onVisibleChanged: {
        if (visible && !root.loading)
            root.playReveal();
    }
    onKeybindsChanged: {
        root.recomputeOffsets();
        if (visible)
            root.playReveal();
    }

    // ---- load keybinds live from Hyprland (`hyprctl binds -j`) ----
    // This host uses hyprlang binds (config/hypr/configs/binds.conf), not bind.lua,
    // so the running compositor is the source of truth.
    readonly property var _modBits: [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]]
    function _categoryFor(dispatcher) {
        switch (dispatcher) {
        case "exec":
            return "Applications";
        case "workspace":
        case "togglespecialworkspace":
            return "Workspaces";
        case "movetoworkspace":
        case "movetoworkspacesilent":
            return "Move Window To Workspace";
        case "killactive":
        case "fullscreen":
        case "fullscreenstate":
        case "togglefloating":
        case "changegroupactive":
        case "togglegroup":
        case "movefocus":
        case "movewindow":
        case "resizeactive":
        case "pseudo":
        case "togglesplit":
        case "mouse":
            return "Windows";
        default:
            return "Other";
        }
    }
    function _keysFor(bind) {
        const keys = [];
        for (const [bit, name] of root._modBits) {
            if ((bind.modmask & bit) !== 0)
                keys.push(name);
        }
        keys.push(bind.key);
        return keys;
    }
    function _buildKeybinds(json) {
        const result = {};
        for (const b of JSON.parse(json)) {
            if (b.submap && b.submap !== "")
                continue;
            const cat = root._categoryFor(b.dispatcher);
            let description = b.has_description ? b.description : root._squeeze(b.dispatcher + " " + (b.arg || ""));
            if (b.release)
                description += " (on release)";
            (result[cat] = result[cat] || []).push({ description: description, keys: root._keysFor(b) });
        }
        return result;
    }
    function _squeeze(s) {
        return s.replace(/\s+/g, " ").trim();
    }
    property bool _finished: false
    function _finish(json) {
        if (root._finished)
            return;
        root._finished = true;
        try {
            root.keybinds = root._buildKeybinds(json || "[]");
        } catch (e) {
            console.warn("[KeyBindsWidget] Failed to parse keybinds:", e);
        }
        root.loading = false;
    }

    Process {
        id: bindsProc
        running: true
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root._finish(text)
        }
    }
    // Watchdog: a wedged hyprctl must not leave the widget spinning forever.
    Timer {
        id: watchdog
        interval: 8000
        running: root.loading
        repeat: false
        onTriggered: root._finish("[]")
    }

    // Empty groups are dropped: comment-only custom files yield categories with
    // no binds, and the rail must not offer entries that lead nowhere.
    property var categories: Object.keys(root.keybinds).filter(c => (root.keybinds[c] || []).length > 0).sort()

    // Shared category navigation: the rail selects a category, scrolls it
    // to the middle of the viewport and applies the distance focus fade.
    CategoryNav {
        // Not `nav`: inside a Repeater delegate an unqualified `nav` resolves to the
        // component's own property, so the id must differ for those bindings.
        id: catNav
        flickable: keyScroll
        content: keyCol
        categories: root.categories
    }

    // ---- UI: persistent category rail + one card per category ----
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing
        opacity: root.revealOpacity

        Label {
            text: "Key Binds"
            font.pixelSize: Theme.fontSize + 4
            font.bold: true
            color: Theme.fg
            Layout.fillWidth: true
        }

        // Loading indicator (centered manually: parent is a layout,
        // which ignores anchors on children)
        AppProgress {
            Layout.alignment: Qt.AlignHCenter
            status: root.loading ? "loading" : "idle"
            variant: "spinner"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacing

            // Category names can be long, so
            // long names elide with a full-name tooltip.
            CategoryRail {
                Layout.preferredWidth: 104
                Layout.alignment: Qt.AlignTop
                visible: !root.loading && root.categories.length > 0
                nav: catNav
                model: root.categories
                currentIndex: catNav.activeIndex
                onSelected: index => catNav.select(index)
            }

            SmoothFlickable {
                id: keyScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: !root.loading
                contentWidth: width
                contentHeight: keyCol.height
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    onPressedChanged: {
                        if (pressed)
                            catNav.cancel();
                    }
                }

                Column {
                    id: keyCol
                    width: keyScroll.width
                    spacing: Theme.spacing

                    Repeater {
                        model: root.categories
                        delegate: Column {
                            id: catSec
                            required property string modelData
                            required property int index
                            property string category: modelData
                            // Direct child of keyCol: CategoryNav finds the
                            // section for centering by this key.
                            property int categoryIndex: index
                            width: parent.width
                            spacing: Theme.spacing
                            // The card owns the fade (hover + scroll anchor); see CategorySection.

                            CategorySection {
                                width: parent.width
                                nav: catNav
                                categoryIndex: catSec.categoryIndex
                                title: catSec.category

                                Repeater {
                                    model: root.keybinds[catSec.category] || []
                                    // Title and keys sit on one line: the description
                                    // elides (tooltip on truncation) to leave the chips room.
                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index
                                        width: parent.width
                                        height: bindBody.implicitHeight + 8
                                        color: "transparent"

                                        RowLayout {
                                            id: bindBody

                                            anchors.fill: parent
                                            anchors.topMargin: 4
                                            anchors.bottomMargin: 4
                                            spacing: Theme.spacing

                                            Label {
                                                id: descriptionLabel
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                text: modelData.description
                                                font.pixelSize: ((typeof Settings !== "undefined") && Settings.keybindsDescriptionFontSize) ? Settings.keybindsDescriptionFontSize : Theme.fontSize
                                                color: Theme.fg
                                                elide: Text.ElideRight
                                                maximumLineCount: 1


                                                HoverHandler {
                                                    id: descriptionHover
                                                }

                                                AppTooltip {
                                                    visible: descriptionHover.hovered && descriptionLabel.truncated
                                                    text: descriptionLabel.text
                                                }
                                            }

                                            // key chips joined by "+" (shared AppKeybind widget)
                                            AppKeybind {
                                                Layout.alignment: Qt.AlignVCenter
                                                keys: modelData.keys || []
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
