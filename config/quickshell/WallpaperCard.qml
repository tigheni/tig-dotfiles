import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Thumbnails of ~/Pictures/Wallpapers (plus the default in the dotfiles).
// A click runs set-wallpaper.sh, which also recolours everything via matugen.
Card {
    id: root

    title: "WALLPAPER"
    property bool active: false
    property var files: []
    property string current: ""

    Process {
        id: list
        command: ["sh", "-c",
            "find \"$HOME/Pictures/Wallpapers\" \"$HOME/.config/hypr/wallpaper\" -maxdepth 1 -type f " +
            "\\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | xargs -r -d '\\n' realpath | sort -u; " +
            "echo; readlink -f \"$XDG_RUNTIME_DIR/wallpaper\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const [found, cur] = text.split("\n\n");
                root.files = found.split("\n").filter(f => f !== "");
                root.current = (cur ?? "").trim();
            }
        }
    }

    Process {
        id: apply
        onExited: list.running = true
    }

    Timer {
        running: root.active
        triggeredOnStart: true
        interval: 10000
        repeat: true
        onTriggered: list.running = true
    }

    Text {
        visible: root.files.length <= 1
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: "add images to ~/Pictures/Wallpapers"
        color: Colors.outline
        font.family: Colors.font
        font.pixelSize: 10
    }

    GridView {
        id: grid
        anchors.fill: parent
        anchors.bottomMargin: root.files.length <= 1 ? 16 : 0
        clip: true
        cellWidth: width / 3
        cellHeight: cellWidth * 9 / 16 + 6
        model: root.files
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            id: cell
            required property string modelData
            readonly property bool selected: modelData === root.current
            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
                radius: 8
                color: Colors.cardHigh
                border.width: cell.selected ? 2 : 0
                border.color: Colors.accent
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: cell.selected ? 2 : 0
                    source: "file://" + cell.modelData
                    sourceSize.width: 200
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.current = cell.modelData;
                        apply.command = [Quickshell.env("DOTFILES_DIR") + "/scripts/set-wallpaper.sh", cell.modelData];
                        apply.running = true;
                    }
                }
            }
        }
    }
}
