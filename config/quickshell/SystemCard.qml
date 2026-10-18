import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// CPU, GPU and RAM as small history graphs, sampled every 2 s.
Card {
    id: root

    title: "SYSTEM"
    readonly property int samples: 40
    property var cpu: []
    property var gpu: []
    property var ram: []
    property int temp: 0
    property var lastCpu: null

    function push(list, v) {
        const l = list.concat([Math.max(0, Math.min(100, v))]);
        return l.length > samples ? l.slice(l.length - samples) : l;
    }

    // Line 1: /proc/stat cpu totals; then MemTotal, MemAvailable (kB);
    // then GPU busy %; then CPU temperature (millidegrees).
    Process {
        id: sample
        command: ["sh", "-c",
            "head -n1 /proc/stat; awk '/^MemTotal|^MemAvailable/ {print $2}' /proc/meminfo; " +
            "cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n1 || echo 0; " +
            "cat /sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1 || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const f = lines[0].split(/\s+/).slice(1).map(Number);
                const idle = f[3] + f[4];
                const total = f.reduce((a, b) => a + b, 0);
                if (root.lastCpu) {
                    const dt = total - root.lastCpu.total;
                    root.cpu = root.push(root.cpu, dt > 0 ? 100 * (1 - (idle - root.lastCpu.idle) / dt) : 0);
                }
                root.lastCpu = { idle, total };
                root.ram = root.push(root.ram, 100 * (1 - Number(lines[2]) / Number(lines[1])));
                root.gpu = root.push(root.gpu, Number(lines[3]) || 0);
                root.temp = Math.round(Number(lines[4]) / 1000);
            }
        }
    }

    Timer {
        running: true
        triggeredOnStart: true
        interval: 2000
        repeat: true
        onTriggered: sample.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Graph { Layout.fillWidth: true; Layout.fillHeight: true; label: "cpu"; values: root.cpu; extra: root.temp ? root.temp + "°" : "" }
        Graph { Layout.fillWidth: true; Layout.fillHeight: true; label: "gpu"; values: root.gpu }
        Graph { Layout.fillWidth: true; Layout.fillHeight: true; label: "ram"; values: root.ram }
    }

    component Graph: RowLayout {
        property string label
        property var values: []
        property string extra: ""
        readonly property real current: values.length ? values[values.length - 1] : 0

        spacing: 10

        Text {
            Layout.preferredWidth: 28
            Layout.alignment: Qt.AlignBottom
            text: label
            color: Colors.accent
            font.family: Colors.font
            font.pixelSize: 11
        }

        Row {
            id: bars
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2
            readonly property real barWidth: (width - spacing * (root.samples - 1)) / root.samples

            Repeater {
                model: root.samples
                Rectangle {
                    required property int index
                    // Right-aligned: newest sample is the last bar.
                    readonly property int i: index - (root.samples - values.length)
                    readonly property real v: i >= 0 ? values[i] : 0
                    width: bars.barWidth
                    height: Math.max(2, bars.height * v / 100)
                    anchors.bottom: parent.bottom
                    radius: 1
                    color: v >= 80 ? Colors.error : v >= 50 ? Colors.warn : Colors.accent
                    opacity: i >= 0 ? 0.35 + 0.65 * (index / root.samples) : 0.15
                }
            }
        }

        Text {
            Layout.preferredWidth: 72
            Layout.alignment: Qt.AlignBottom
            horizontalAlignment: Text.AlignRight
            text: Math.round(current) + "%" + (extra ? "  " + extra : "")
            color: Colors.fg
            font.family: Colors.font
            font.pixelSize: 11
        }
    }
}
