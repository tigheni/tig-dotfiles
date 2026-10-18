import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

// Whatever MPRIS player is playing (Spotify, Brave, mpv), else the first one.
Card {
    id: root

    property bool active: false
    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: players.find(p => p.playbackState === MprisPlaybackState.Playing)
        ?? players.find(p => p.identity === "Spotify") ?? players[0] ?? null
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing

    function clock(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // MPRIS doesn't push position updates; poll while it's visible.
    Timer {
        running: root.active && root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Text {
        visible: !root.player
        anchors.centerIn: parent
        text: "󰝛  Nothing playing"
        color: Colors.outline
        font.family: Colors.font
        font.pixelSize: 13
    }

    RowLayout {
        visible: !!root.player
        anchors.fill: parent
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 150
            Layout.preferredHeight: 150
            Layout.alignment: Qt.AlignVCenter
            radius: 10
            color: Colors.cardHigh
            clip: true

            Text {
                anchors.centerIn: parent
                text: "󰎆"
                color: Colors.outline
                font.family: Colors.font
                font.pixelSize: 48
                visible: art.status !== Image.Ready
            }

            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            Text {
                text: root.player?.identity ?? ""
                color: Colors.accent
                font.family: Colors.font
                font.pixelSize: 10
            }

            Text {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Unknown title"
                color: Colors.fg
                font.family: Colors.font
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.player?.trackArtist || ""
                color: Colors.fgDim
                font.family: Colors.font
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            // Progress bar; click to seek.
            Rectangle {
                id: track
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: Colors.cardHigh
                visible: (root.player?.length ?? 0) > 0

                Rectangle {
                    width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                    height: parent.height
                    radius: 2
                    color: Colors.accent
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    enabled: root.player?.canSeek ?? false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => root.player.position = mouse.x / track.width * root.player.length
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: track.visible

                Text {
                    text: root.clock(root.player?.position ?? 0)
                    color: Colors.outline
                    font.family: Colors.font
                    font.pixelSize: 10
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.clock(root.player?.length ?? 0)
                    color: Colors.outline
                    font.family: Colors.font
                    font.pixelSize: 10
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 22

                MediaButton {
                    glyph: "󰒮"
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }
                MediaButton {
                    glyph: root.playing ? "󰏤" : "󰐊"
                    big: true
                    onClicked: root.player.togglePlaying()
                }
                MediaButton {
                    glyph: "󰒭"
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player.next()
                }
            }
        }
    }

    component MediaButton: Text {
        property string glyph
        property bool big: false
        signal clicked

        text: glyph
        color: !enabled ? Colors.outline : big ? Colors.accent : Colors.fg
        font.family: Colors.font
        font.pixelSize: big ? 26 : 18

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            enabled: parent.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
