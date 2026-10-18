import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Month view with today highlighted, plus current weather from wttrbar.
Card {
    id: root

    property bool active: false
    property date now: new Date()
    property string weatherIcon: ""
    property string weatherText: ""

    readonly property int year: now.getFullYear()
    readonly property int month: now.getMonth()
    // Monday-first offset of the 1st, and the month length.
    readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7
    readonly property int days: new Date(year, month + 1, 0).getDate()

    Timer {
        running: root.active
        triggeredOnStart: true
        interval: 60000
        repeat: true
        onTriggered: root.now = new Date()
    }

    Process {
        id: weather
        command: ["wttrbar", "--nerd"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const w = JSON.parse(text);
                    const parts = w.text.split(" ");
                    const desc = w.tooltip.split("\n")[0].replace(/<[^>]+>/g, "").replace(/\s+\d+°.*/, "").trim();
                    root.weatherIcon = parts[0];
                    root.weatherText = parts.slice(1).join(" ") + "° " + desc;
                } catch (e) {}
            }
        }
    }

    Timer {
        running: true
        triggeredOnStart: true
        interval: 15 * 60000
        repeat: true
        onTriggered: weather.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: Qt.formatDate(root.now, "MMMM yyyy")
                color: Colors.fg
                font.family: Colors.font
                font.pixelSize: 13
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.weatherIcon
                color: Colors.accent
                font.family: Colors.font
                font.pixelSize: 14
            }
            Text {
                text: root.weatherText
                color: Colors.fgDim
                font.family: Colors.font
                font.pixelSize: 11
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 1
            columnSpacing: 0

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Text {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Colors.outline
                    font.family: Colors.font
                    font.pixelSize: 10
                }
            }

            Repeater {
                model: 42

                Item {
                    required property int index
                    readonly property int day: index - root.offset + 1
                    readonly property bool inMonth: day >= 1 && day <= root.days
                    readonly property bool today: inMonth && day === root.now.getDate()

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: index < Math.ceil((root.offset + root.days) / 7) * 7

                    Rectangle {
                        anchors.centerIn: parent
                        width: 20
                        height: 16
                        radius: 8
                        color: Colors.accent
                        visible: parent.today
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.inMonth ? parent.day : ""
                        color: parent.today ? Colors.bg : (parent.index % 7 >= 5 ? Colors.fgDim : Colors.fg)
                        font.family: Colors.font
                        font.pixelSize: 10
                        font.bold: parent.today
                    }
                }
            }
        }
    }
}
