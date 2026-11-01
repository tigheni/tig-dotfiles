import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.widgets.shared

// Clipboard history popup (Super+Shift+V): a card centered on the focused monitor,
// independent of the bar. Type to filter, Up/Down to move, Enter or click to copy,
// Delete to drop an entry, Escape or a click outside to close.
Scope {
    id: root

    property bool shown: false
    property var targetScreen: null
    property string query: ""

    readonly property var entries: {
        const q = root.query.toLowerCase().trim();
        const out = [];
        for (const entry of ClipboardService.history) {
            if (q === "" || String(entry.content || "").toLowerCase().includes(q))
                out.push(entry);
            if (out.length >= 200)
                break;
        }
        return out;
    }

    function focusedScreen() {
        const focused = Hyprland.focusedMonitor;
        if (focused) {
            for (const screen of Quickshell.screens) {
                if ((Hyprland.monitorFor(screen)?.name ?? screen.name ?? "") === focused.name)
                    return screen;
            }
        }
        return Quickshell.screens[0] ?? null;
    }

    function open() {
        root.targetScreen = root.focusedScreen();
        root.query = "";
        root.shown = true;
    }

    function close() {
        root.shown = false;
    }

    function toggle() {
        if (root.shown)
            root.close();
        else
            root.open();
    }

    // Images and file lists go back with their own MIME type so pasting into a
    // browser or file manager gets the image/file, not its cache path.
    function copyEntry(entry) {
        if (!entry)
            return;
        if (entry.type === "image")
            Quickshell.execDetached(["sh", "-c", 'wl-copy --type "$1" < "$2"', "sh", entry.mimeType || "image/png", entry.content]);
        else if (entry.type === "uri-list")
            Quickshell.execDetached(["sh", "-c", 'printf "file://%s" "$1" | wl-copy --type text/uri-list', "sh", entry.content]);
        else
            ClipboardService.copy(entry.content);
        root.close();
    }

    IpcHandler {
        target: "clipboardPopup"

        function toggle(): string {
            root.toggle();
            return root.shown ? "opened" : "closed";
        }

        function close(): string {
            root.close();
            return "closed";
        }
    }

    LazyLoader {
        active: root.shown

        PanelWindow {
            id: win
            screen: root.targetScreen
            visible: true
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "archeclipse-clipboard"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // Dimmed backdrop: a click anywhere outside the card closes it.
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.35 * card.t)
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.min(640, parent.width - 64)
                height: Math.min(520, parent.height - 64)
                radius: Theme.radius + 4
                color: Theme.bg
                border.color: Theme.border
                border.width: 1
                clip: true

                property real t: 0
                opacity: t
                scale: 0.96 + 0.04 * t
                Behavior on t {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
                Component.onCompleted: {
                    card.t = 1;
                    search.forceActiveFocus();
                }

                // Swallow clicks so they don't reach the backdrop.
                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.pad
                    spacing: Theme.spacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing

                        Text {
                            text: Icons.clipboard
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 4
                        }
                        Text {
                            text: "Clipboard"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 2
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.entries.length + (root.query !== "" ? " matches" : " items")
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    AppTextField {
                        id: search
                        Layout.fillWidth: true
                        implicitHeight: 36
                        placeholderText: "Search clipboard history"
                        onTextChanged: {
                            root.query = text;
                            list.currentIndex = 0;
                        }
                        Keys.onEscapePressed: root.close()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onReturnPressed: root.copyEntry(root.entries[list.currentIndex])
                        Keys.onEnterPressed: root.copyEntry(root.entries[list.currentIndex])
                        Keys.onDeletePressed: event => {
                            // Delete edits the search text while there is any;
                            // with an empty field it drops the selected entry.
                            if (search.text !== "" || list.currentIndex < 0) {
                                event.accepted = false;
                                return;
                            }
                            const entry = root.entries[list.currentIndex];
                            if (entry)
                                ClipboardService.remove(entry.id);
                        }
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: root.entries
                        currentIndex: 0
                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: 0
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool isImage: modelData.type === "image"
                            readonly property bool selected: ListView.isCurrentItem

                            width: ListView.view.width
                            height: isImage ? 96 : 40
                            radius: Theme.radius
                            color: selected ? Theme.surfaceActive : (rowMouse.containsMouse ? Theme.surface : "transparent")
                            border.color: selected ? Theme.accent : "transparent"
                            border.width: 1

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: list.currentIndex = row.index
                                onClicked: root.copyEntry(row.modelData)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: Theme.spacing

                                Text {
                                    visible: !row.isImage
                                    text: row.modelData.type === "uri-list" ? Icons.file : Icons.clipboard
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                }
                                Image {
                                    visible: row.isImage
                                    Layout.preferredHeight: 80
                                    Layout.preferredWidth: 140
                                    source: row.isImage ? "file://" + row.modelData.content : ""
                                    fillMode: Image.PreserveAspectFit
                                    horizontalAlignment: Image.AlignLeft
                                    asynchronous: true
                                    sourceSize.height: 160
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: row.isImage ? "Image" : String(row.modelData.content).replace(/\s+/g, " ").slice(0, 300)
                                    color: row.isImage ? Theme.fgDim : Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.entries.length === 0
                            text: root.query !== "" ? "No matches" : "Clipboard history is empty"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Enter copy · Del remove · Esc close"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
