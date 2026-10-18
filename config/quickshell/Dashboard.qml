import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Dropdown under Waybar: media, today, calendar and system on top; quick
// toggles, recent notifications and the wallpaper picker below.
// Toggled with `qs ipc call dashboard toggle` (Super+D); Escape or a click
// outside closes it.
PanelWindow {
    id: win

    property bool open: false

    anchors { top: true; left: true; right: true }
    // On the top layer (like Waybar), Hyprland places it below Waybar when the
    // bar is shown and at the screen edge when it is hidden.
    margins { top: 6; left: 8; right: 8 }
    exclusiveZone: 0
    implicitHeight: 380
    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-dashboard"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Map the window before sliding in; unmap it once the slide-out ends.
    onOpenChanged: {
        if (open)
            visible = true;
        else
            hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 240
        onTriggered: if (!win.open) win.visible = false
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.open && win.visible
        onCleared: win.open = false
    }

    Rectangle {
        id: panel

        width: parent.width
        height: parent.height
        y: win.open ? 0 : -height - 12
        opacity: win.open ? 1 : 0
        radius: 16
        color: Colors.bg
        border.width: 1
        border.color: Qt.alpha(Colors.fg, 0.12)
        focus: true

        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Keys.onEscapePressed: win.open = false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: 194
                Layout.maximumHeight: 194
                spacing: 10

                MediaCard {
                    Layout.preferredWidth: 400
                    Layout.fillHeight: true
                    active: win.open
                }
                DayCard {
                    Layout.preferredWidth: 300
                    Layout.fillHeight: true
                    active: win.open
                }
                CalendarCard {
                    Layout.preferredWidth: 270
                    Layout.fillHeight: true
                    active: win.open
                }
                SystemCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                TogglesCard {
                    Layout.preferredWidth: 400
                    Layout.fillHeight: true
                    active: win.open
                }
                NotificationsCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: win.open
                }
                WallpaperCard {
                    Layout.preferredWidth: 340
                    Layout.fillHeight: true
                    active: win.open
                }
            }
        }
    }
}
