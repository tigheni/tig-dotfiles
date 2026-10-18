import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Recent notifications from mako's history (newest first), including the
// ones hidden while do-not-disturb was on.
Card {
    id: root

    title: "NOTIFICATIONS" + (items.length ? "  ·  " + items.length : "")
    property bool active: false
    property var items: []
    readonly property int shown: 6

    Process {
        id: fetch
        command: ["makoctl", "history", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.items = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Timer {
        running: root.active
        triggeredOnStart: true
        interval: 5000
        repeat: true
        onTriggered: fetch.running = true
    }

    Text {
        visible: root.items.length === 0
        anchors.centerIn: parent
        text: "󰂚  No notifications"
        color: Colors.outline
        font.family: Colors.font
        font.pixelSize: 13
    }

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 6
        columnSpacing: 8

        Repeater {
            model: root.items.slice(0, root.shown)

            Rectangle {
                id: item
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignTop
                radius: 8
                color: Colors.cardHigh

                Rectangle {
                    width: 3
                    height: parent.height - 12
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: item.modelData.urgency === "critical" ? Colors.error : Colors.accent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 10
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: item.modelData.summary || "(no title)"
                            textFormat: Text.PlainText
                            color: Colors.fg
                            font.family: Colors.font
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: item.modelData.app_name === "notify-send" ? "" : (item.modelData.app_name ?? "")
                            color: Colors.outline
                            font.family: Colors.font
                            font.pixelSize: 9
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: (item.modelData.body ?? "").replace(/<[^>]+>/g, "").replace(/\s+/g, " ")
                        textFormat: Text.PlainText
                        color: Colors.fgDim
                        font.family: Colors.font
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Keeps the items packed at the top when there are fewer than six.
        Item {
            Layout.columnSpan: 2
            Layout.fillHeight: true
        }
    }
}
