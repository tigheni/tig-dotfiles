import QtQuick
import Quickshell.Io
import qs.theme

// Voxtype dictation state (Super+V): a red mic while recording, an accent mic while the
// recording is transcribed; hidden when idle. Fed by `voxtype status --follow`, one JSON
// object per state change ({"class": "idle" | "recording" | "transcribing", ...}).
Item {
    id: root
    property string state_: "idle"
    readonly property bool recording: root.state_ === "recording"
    readonly property bool transcribing: root.state_ === "transcribing"

    visible: root.recording || root.transcribing
    width: visible ? icon.implicitWidth + 8 : 0
    height: Theme.barContentHeight

    Text {
        id: icon
        anchors.centerIn: parent
        text: Icons.micOn
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 2
        color: root.recording ? Theme.danger : Theme.accent

        SequentialAnimation on opacity {
            running: root.recording
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation {
                to: 0.35
                duration: 600
            }
            NumberAnimation {
                to: 1
                duration: 600
            }
        }
    }

    Process {
        id: statusProc
        running: true
        command: ["voxtype", "status", "--follow", "--format", "json"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.state_ = String(JSON.parse(data).class || "idle");
                } catch (e) {}
            }
        }
        // The daemon restarts with the session (voxtype.service); retry instead of
        // leaving the indicator stuck.
        onExited: {
            root.state_ = "idle";
            restartTimer.restart();
        }
    }
    Timer {
        id: restartTimer
        interval: 5000
        onTriggered: statusProc.running = true
    }
}
