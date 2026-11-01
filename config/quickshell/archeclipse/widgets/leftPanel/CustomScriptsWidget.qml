import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.theme
import qs.widgets.shared
import qs.services

// Custom Scripts widget — scrollable list of utility scripts: screenshot and record entries route
// through the Screenshot and ScreenRecorder services, everything else spawns via execDetached; a
// missing binary greys its row out.
Item {
    id: root

    property string monitorName: ""

    // Utility script definitions — icons are Nerd Font codepoints. kind marks entries whose
    // callback does more than a plain exec (screenshot, record toggle, file manager, reset confirmation).
    property var scriptDefs: [
        {
            name: "Restart Bar",
            icon: Icons.restartBar,
            description: "Restart the shell bar",
            keybind: [],
            command: "\"$DOTFILES_DIR/scripts/archeclipse.sh\" restart"
        },
        {
            name: "HyprPicker",
            icon: Icons.colorPicker,
            description: "Color Picker for Hyprland",
            app: "hyprpicker",
            command: "hyprpicker"
        },
        {
            name: "Clear Clipboard",
            icon: Icons.clearClipboard,
            description: "Clear clipboard history",
            app: "wl-copy",
            command: "wl-copy --clear"
        },
        {
            name: "Screenshot Screen",
            icon: Icons.screenshotScreen,
            description: "Screenshot entire screen",
            keybind: [],
            app: "flameshot",
            kind: "screenshot-now"
        },
        {
            name: "Screenshot Area",
            icon: Icons.screenshotScreen,
            description: "Select area to screenshot",
            keybind: ["Print"],
            app: "flameshot",
            kind: "screenshot-area"
        },
        {
            name: "Record Screen",
            icon: Icons.screenshotWindow,
            description: "Start/stop recording the screen",
            keybind: ["SUPER", "Print"],
            app: "gpu-screen-recorder",
            kind: "record-now"
        },
        {
            name: "Record Area",
            icon: Icons.screenshotWindow,
            description: "Start/stop recording a selected area",
            keybind: ["SUPER", "SHIFT", "Print"],
            app: "gpu-screen-recorder",
            kind: "record-area"
        },
        {
            name: "Refresh Hyprland",
            icon: Icons.thermometer,
            description: "Refresh Hyprland (reload config)",
            command: "hyprctl reload"
        },
        {
            name: "System Monitor",
            icon: Icons.btop,
            description: "Open system monitor",
            app: "btop",
            command: "wezterm start -- btop"
        },
        {
            name: "Volume Control",
            icon: Icons.cava,
            description: "Adjust volume",
            app: "pavucontrol",
            command: "pavucontrol"
        },
        {
            name: "File Manager",
            icon: Icons.folder,
            description: "Open the configured file manager",
            kind: "file-manager"
        },
        {
            name: "Visual Studio Code",
            icon: Icons.vscode,
            description: "Code Editor",
            app: "code",
            command: "code"
        },
        {
            name: "Reset Settings",
            icon: Icons.restartBar,
            description: "Reset all shell settings to default",
            kind: "reset-settings"
        }
    ]

    // app availability: filled async on load. Reassigned (not mutated) so
    // bindings re-evaluate when each check finishes.
    property var appStatus: ({})

    // Replayable staggered reveal: tabs are built hidden at startup, so creation-time timers
    // fire unseen — a counter steps 0→N on visibility and rows key opacity off their index.
    property int revealCount: 0
    Timer {
        id: revealTimer
        interval: 30
        repeat: true
        onTriggered: {
            if (root.revealCount >= root.scriptDefs.length)
                revealTimer.stop();
            else
                root.revealCount++;
        }
    }
    function playReveal() {
        root.revealCount = 0;
        revealTimer.restart();
    }
    onVisibleChanged: {
        if (visible)
            root.playReveal();
    }

    Component.onCompleted: {
        refreshAppStatus();
        if (visible)
            playReveal();
    }

    function refreshAppStatus() {
        const needed = [];
        for (const s of scriptDefs)
            if (s.app)
                needed.push(s.app);
        const unique = needed.filter((v, i, a) => a.indexOf(v) === i);
        for (const app of unique) {
            const chk = appCheckComp.createObject(root, {
                appName: app
            });
            chk.running = true;
        }
    }

    property Component appCheckComp: Component {
        Process {
            id: _appChk
            property string appName: ""
            command: ["bash", "-c", "command -v " + appName + " >/dev/null 2>&1 && echo true || echo false"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const s = Object.assign({}, root.appStatus);
                    s[_appChk.appName] = text.trim() === "true";
                    root.appStatus = s;
                    _appChk.destroy();
                }
            }
        }
    }

    property Component resetProcComp: Component {
        Process {
            id: _resetProc
            command: ["bash", "-c", "rm -rf $HOME/.cache/quickshell/settings/settings.json"]
            stdout: StdioCollector {
                onStreamFinished: {
                    // Restart the shell so it reloads the defaults instead of
                    // rewriting the old in-memory settings.
                    Quickshell.execDetached([Quickshell.env("DOTFILES_DIR") + "/scripts/archeclipse.sh", "restart"]);
                    _resetProc.destroy();
                }
            }
        }
    }

    function displayName(def) {
        if (def.kind === "file-manager")
            return "File Manager";
        return def.name;
    }

    function runScript(def) {
        // Special-kind callbacks that are more than a plain exec
        if (def.kind === "screenshot-now") {
            Screenshot.capture("now", root.monitorName);
            return;
        }
        if (def.kind === "screenshot-area") {
            Screenshot.capture("area", root.monitorName);
            return;
        }
        if (def.kind === "record-now") {
            ScreenRecorder.toggleRecording("now", root.monitorName);
            return;
        }
        if (def.kind === "record-area") {
            ScreenRecorder.toggleRecording("area", root.monitorName);
            return;
        }
        // Spawn via Quickshell.execDetached, NOT Hyprland.dispatch("exec ..."): Hyprland >= 0.55
        // (Lua config) rejects that syntax, so every click silently did nothing.
        if (def.kind === "file-manager") {
            // nautilus, matching $fileManager in config/hypr: the xdg default for
            // directories here is an editor (cursor.desktop), not a file manager.
            Quickshell.execDetached(["nautilus", Quickshell.env("HOME")]);
            return;
        }
        if (def.command)
            Quickshell.execDetached(["bash", "-c", def.command]);
    }

    function appInstalled(def) {
        if (!def.app)
            return true;
        const st = root.appStatus[def.app];
        return st === undefined ? true : st;
    }

    function doReset() {
        const proc = resetProcComp.createObject(root);
        proc.running = true;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing

        Label {
            text: "Custom Scripts"
            font.pixelSize: Theme.fontSize + 4
            font.bold: true
            color: Theme.fg
            Layout.fillWidth: true
        }

        SmoothFlickable {
            id: scriptScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: scriptCol.height
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Column {
                id: scriptCol
                spacing: Theme.spacing
                width: scriptScroll.width
                // No edge padding: the panel owns the content inset (the
                // island's Theme.pad), right-panel parity.

                Repeater {
                    model: root.scriptDefs
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        property bool confirming: false
                        width: parent.width
                        implicitHeight: rowContent.implicitHeight + 20
                        color: Theme.surface
                        radius: Theme.radius
                        // Row appears when the reveal counter passes its
                        // position (see root.playReveal).
                        opacity: index < root.revealCount ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }

                        // The whole row is the script button — click runs it.
                        // Reset shows a Yes/No confirmation instead.
                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.appInstalled(modelData)
                            onClicked: {
                                if (modelData.kind === "reset-settings")
                                    confirming = true;
                                else
                                    root.runScript(modelData);
                            }
                            AppTooltip {
                                visible: rowMouse.containsMouse
                                text: root.appInstalled(modelData) ? modelData.description : modelData.description + " (Requires installation)"
                            }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.pad
                            spacing: Theme.spacing

                            // NOTE: RowLayout (not Row) — verticalCenter anchors are ignored
                            // inside positioners, so alignment goes through Layout.alignment.
                            RowLayout {
                                id: rowContent
                                spacing: Theme.spacing
                                width: parent.width

                                Label {
                                    text: modelData.icon
                                    width: 28
                                    font.pixelSize: Theme.fontSize + 4
                                    color: Theme.accent
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2
                                    Label {
                                        text: root.displayName(modelData)
                                        font.pixelSize: Theme.fontSize + 1
                                        font.bold: true
                                        color: Theme.fg
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        width: parent.width
                                    }
                                    Label {
                                        text: root.appInstalled(modelData) ? modelData.description : modelData.description + " (Requires installation)"
                                        font.pixelSize: Theme.fontSize - 1
                                        color: Theme.fgDim
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        width: parent.width
                                    }
                                }

                                // Keybind display (shared AppKeybind widget)
                                AppKeybind {
                                    keys: modelData.keybind || []
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            // Reset confirmation (Yes/No buttons)
                            RowLayout {
                                visible: modelData.kind === "reset-settings" && confirming
                                spacing: Theme.spacing
                                width: parent.width
                                Label {
                                    text: "Reset all settings?"
                                    color: Theme.fg
                                    font.pixelSize: Theme.fontSize
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                AppButton {
                                    text: "Yes"
                                    tooltipText: "Confirm the settings reset"
                                    Layout.alignment: Qt.AlignVCenter
                                    onClicked: {
                                        confirming = false;
                                        root.doReset();
                                    }
                                }
                                AppButton {
                                    text: "No"
                                    tooltipText: "Cancel the reset"
                                    Layout.alignment: Qt.AlignVCenter
                                    onClicked: confirming = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
