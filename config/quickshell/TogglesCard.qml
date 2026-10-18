import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// One-click switches, backed by scripts/dashboard-toggles.sh.
Card {
    id: root

    title: "QUICK TOGGLES"
    property bool active: false
    property var toggleState: ({})
    readonly property string script: Quickshell.env("DOTFILES_DIR") + "/scripts/dashboard-toggles.sh"

    readonly property var toggles: [
        { key: "vpn", label: "VPN", on: "󰖂", off: "󰖂", onText: "connected", offText: "off" },
        { key: "bluetooth", label: "Bluetooth", on: "󰂯", off: "󰂲", onText: "on", offText: "off" },
        { key: "night", label: "Night light", on: "󰖔", off: "󰖙", onText: "warm", offText: "off" },
        { key: "mic", label: "Mic", on: "󰍬", off: "󰍭", onText: "on", offText: "muted" },
        { key: "awake", label: "Stay awake", on: "󰅶", off: "󰾪", onText: "on", offText: "off" },
        { key: "dnd", label: "Silent", on: "󰂛", off: "󰂚", onText: "on", offText: "off" }
    ]

    function flip(key) {
        // Show the change at once; the next status poll confirms it.
        const s = Object.assign({}, toggleState);
        s[key] = !s[key];
        toggleState = s;
        runner.command = [script, "toggle", key];
        runner.running = true;
    }

    Process {
        id: status
        command: [root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.toggleState = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: runner
        onExited: refresh.restart()
    }

    Timer {
        id: refresh
        interval: 600
        onTriggered: status.running = true
    }

    Timer {
        running: root.active
        triggeredOnStart: true
        interval: 3000
        repeat: true
        onTriggered: status.running = true
    }

    GridLayout {
        anchors.fill: parent
        columns: 3
        rowSpacing: 8
        columnSpacing: 8

        Repeater {
            model: root.toggles

            Rectangle {
                id: tile
                required property var modelData
                readonly property bool on: root.toggleState[modelData.key] === true

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: on ? Colors.accent : Colors.cardHigh
                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: tile.on ? tile.modelData.on : tile.modelData.off
                        color: tile.on ? Colors.bg : Colors.fg
                        font.family: Colors.font
                        font.pixelSize: 18
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: tile.modelData.label
                            color: tile.on ? Colors.bg : Colors.fg
                            font.family: Colors.font
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: tile.on ? tile.modelData.onText : tile.modelData.offText
                            color: tile.on ? Qt.alpha(Colors.bg, 0.7) : Colors.outline
                            font.family: Colors.font
                            font.pixelSize: 10
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.flip(tile.modelData.key)
                }
            }
        }
    }
}
