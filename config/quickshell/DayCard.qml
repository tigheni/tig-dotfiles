import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Today's numbers from daytrack (scripts/daytrack.sh dash).
Card {
    id: root

    title: "TODAY"
    property bool active: false
    property var day: ({ prod: 0, goal: 1, streak: 0, deepmin: 1500, deep: 0, away: "off", cat: "", proj: "", top: [] })
    readonly property real progress: Math.min(1, day.prod / Math.max(1, day.goal))
    readonly property bool deepNow: day.streak >= day.deepmin && day.away === ""

    function fmt(s) {
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
        return h > 0 ? h + "h" + String(m).padStart(2, "0") : m + "m";
    }

    Process {
        id: fetch
        command: [Quickshell.env("DOTFILES_DIR") + "/scripts/daytrack.sh", "dash"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.day = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Timer {
        running: root.active
        triggeredOnStart: true
        interval: 10000
        repeat: true
        onTriggered: fetch.running = true
    }

    // Refresh "now" right after a focus change instead of on the next
    // poll; the delay lets daytrack classify the new window first.
    Connections {
        target: Hyprland
        enabled: root.active

        function onRawEvent(event) {
            if (event.name === "activewindow")
                focusDelay.restart();
        }
    }

    Timer {
        id: focusDelay
        interval: 300
        onTriggered: fetch.running = true
    }

    RowLayout {
        anchors.fill: parent
        spacing: 14

        ColumnLayout {
            Layout.preferredWidth: 104
            Layout.fillHeight: true
            spacing: 6

            // Goal ring
            Item {
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                Layout.alignment: Qt.AlignHCenter

                Canvas {
                    id: ring
                    anchors.fill: parent
                    property real value: root.progress
                    property color fill: root.progress >= 1 || root.deepNow ? Colors.accent : Colors.fgDim
                    onValueChanged: requestPaint()
                    onFillChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        const r = width / 2 - 6;
                        ctx.reset();
                        ctx.lineWidth = 8;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Colors.cardHigh;
                        ctx.beginPath();
                        ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI);
                        ctx.stroke();
                        if (value > 0) {
                            ctx.strokeStyle = fill;
                            ctx.beginPath();
                            ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + value * 2 * Math.PI);
                            ctx.stroke();
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.fmt(root.day.prod)
                        color: Colors.fg
                        font.family: Colors.font
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "of " + root.fmt(root.day.goal)
                        color: Colors.outline
                        font.family: Colors.font
                        font.pixelSize: 10
                    }
                }
            }

            // Last 7 days: one bar per day, full height = the daily goal (or the
            // best day if that's higher). Days that met the goal are highlighted.
            Row {
                id: week
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4
                readonly property var days: root.day.week ?? []
                readonly property real maxSecs: Math.max(root.day.goal, ...days.map(d => d.secs), 1)

                Repeater {
                    model: week.days

                    Column {
                        id: dayBar
                        required property var modelData
                        required property int index
                        readonly property bool today: index === week.days.length - 1
                        width: (week.width - week.spacing * 6) / 7
                        height: week.height
                        spacing: 2

                        Item {
                            width: parent.width
                            height: parent.height - 13

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: Math.max(2, parent.height * dayBar.modelData.secs / week.maxSecs)
                                radius: 2
                                color: dayBar.modelData.secs >= root.day.goal || dayBar.today ? Colors.accent : Colors.fgDim
                                opacity: dayBar.today || dayBar.modelData.secs >= root.day.goal ? 1 : 0.45
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: dayBar.modelData.day.charAt(0)
                            color: dayBar.today ? Colors.accent : Colors.outline
                            font.family: Colors.font
                            font.pixelSize: 9
                            font.bold: dayBar.today
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5

            Text {
                Layout.fillWidth: true
                text: root.day.away === "off" ? "󰅙  tracker not running"
                    : root.day.away === "paused" ? "󰏤  paused"
                    : root.day.away !== "" ? "󰒲  away"
                    : root.deepNow ? "󰈸  deep work · " + root.fmt(root.day.streak)
                    : "󱎫  streak " + root.fmt(root.day.streak)
                color: root.deepNow ? Colors.accent : Colors.fg
                font.family: Colors.font
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.day.cat !== "" && root.day.away === ""
                text: "now: " + root.day.cat + (root.day.proj ? " · " + root.day.proj : "")
                color: Colors.fgDim
                font.family: Colors.font
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                text: root.day.deep + " deep session" + (root.day.deep === 1 ? "" : "s")
                color: Colors.outline
                font.family: Colors.font
                font.pixelSize: 11
            }

            Item { Layout.fillHeight: true }

            Repeater {
                model: root.day.top

                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: Colors.fg
                            font.family: Colors.font
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                        Text {
                            text: root.fmt(modelData.secs)
                            color: Colors.outline
                            font.family: Colors.font
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
                        radius: 2
                        color: Colors.cardHigh
                        Rectangle {
                            width: parent.width * modelData.secs / Math.max(1, root.day.prod)
                            height: parent.height
                            radius: 2
                            color: Colors.accent
                        }
                    }
                }
            }
        }
    }
}
