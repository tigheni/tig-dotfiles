import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.widgets.bar.islands
import qs.widgets.leftPanel

// LeftIsland: the former LeftPanel body in the left side pill, scoped to its monitor; same
// expand-driver unfold as SearchIsland, tabs built on first select and kept alive after.
Item {
    id: root
    width: Settings.panelWidthFor("left", root.monitorName)
    // Explicit full height, NOT implicit: positioner implicit sizes freeze at completion time,
    // so an animated-only height never reached the pill; the Loader measures this one.
    height: bodyHeight

    // Island owner passes the bar's monitor; body falls back to focused.
    property string monitorName: ""
    // Monitor screen object (ShellScreen) passed by the bar owner.
    property var screen: null

    // Full monitor height from the bar owner: side islands stretch the whole vertical screen
    // like the old edge panels (the pill adds 10px padding, leaving a 5px bottom margin).
    property int screenHeight: (screen && screen.height > 0) ? screen.height : 1080

    // Fixed dropdown height: the island is a floating card, each widget fills this viewport
    // and scrolls internally (like the search island's fixed body height).
    property int bodyHeight: Math.max(400, screenHeight - 15)

    // Expand driver: 0 -> 1 on creation unfolds the body.
    property real expand: 0
    // Tab-name order for the rail index mapping; names keep the QS "Widget" suffix for IPC
    // showWidget/widgetState compat.
    readonly property var tabOrder: ["SettingsWidget", "CustomScripts", "KeyBinds"]
    function tabIndex(name) {
        const i = root.tabOrder.indexOf(name);
        return i >= 0 ? i : root.tabOrder.indexOf("SettingsWidget");
    }
    Component.onCompleted: {
        expand = 1;
        Registry.register(root.registryKey(), root);
        Registry.register("left-island", root);
        // Prime the initially-selected tab so its Loader activates below.
        var v = Object.assign({}, root._visited);
        v[root.selectedWidget] = true;
        root._visited = v;
    }
    onMonitorNameChanged: {
        if (root.monitorName !== "")
            Registry.register(root.registryKey(), root);
        root.syncSelectedWidget();
    }
    Component.onDestruction: {
        Registry.unregister("left-island");
        Registry.unregister(root.registryKey());
    }
    function registryKey() {
        return `left-island-${root.monitorName || Registry.monitorName}`;
    }

    // Per-monitor selected tab, with the persisted global tab as fallback
    // for monitors that do not have an override yet.
    property string selectedWidget: Settings.leftPanelWidgetFor(root.monitorName)
    property bool _restoringSelectedWidget: false
    function syncSelectedWidget() {
        const selected = Settings.leftPanelWidgetFor(root.monitorName);
        if (root.selectedWidget === selected)
            return;
        root._restoringSelectedWidget = true;
        root.selectedWidget = selected;
        root._restoringSelectedWidget = false;
    }
    // Tabs visited this session — a tab's Loader activates on first select
    // and stays active (object replaced, never mutated, for change notify).
    property var _visited: ({})
    function tabPrimed(name) {
        return root.selectedWidget === name || root._visited[name] === true;
    }
    onSelectedWidgetChanged: {
        // Skip no-op writes: each one replaces leftPanelByMonitor, which re-evaluates the
        // selectedWidget binding from inside its own change handler (a binding loop).
        if (!root._restoringSelectedWidget && Settings.leftPanelWidgetFor(root.monitorName) !== selectedWidget)
            Settings.setLeftPanelWidgetFor(root.monitorName, selectedWidget);
        if (root._visited[selectedWidget] !== true) {
            var v = Object.assign({}, root._visited);
            v[selectedWidget] = true;
            root._visited = v;
        }
        switchAnim.restart();
    }
    Connections {
        target: Settings
        function onLeftPanelWidgetChanged() {
            const entry = (Settings.leftPanelByMonitor || {})[root.monitorName];
            if (!entry || entry.widget === undefined)
                root.syncSelectedWidget();
        }
        function onLeftPanelByMonitorChanged() {
            root.syncSelectedWidget();
        }
    }
    // Expose the active tab's widget so IPC can poke the live widget without traversing the
    // tree; unvisited tabs have no item, and callers null-check.
    readonly property var activeWidget: {
        switch (widgetStack.currentIndex) {
        case 0:
            return settingsLoader.item;
        case 1:
            return scriptsLoader.item;
        case 2:
            return keybindsLoader.item;
        default:
            return null;
        }
    }

    // Build a tab's Loader without switching to it or opening the island
    // (primes on demand, e.g. floating a dialog from another widget).
    function primeTab(name) {
        if (root._visited[name] !== true) {
            var v = Object.assign({}, root._visited);
            v[name] = true;
            root._visited = v;
        }
    }

    // Hover tracking lives here (stable container — content never swaps under the cursor).
    // Leaving arms the close timer, which re-checks so a fast flick still closes.
    HoverHandler {
        id: islandHover
        onHoveredChanged: {
            if (islandHover.hovered) {
                leaveTimer.stop();
                // Pin hover-driven islands so a hold expiry can't close
                // the panel while it is being used.
                BarState.activate("left", 0, root.monitorName);
            } else {
                root.requestAutoHide();
            }
        }
    }
    function requestAutoHide() {
        if (BarState.tourHoldFor(root.monitorName))
            return;
        if (Settings.panelLockFor("left", root.monitorName))
            return;
        if (islandHover.hovered)
            return;
        if (root.activeWidget && root.activeWidget.popupHovered)
            return;
        leaveTimer.restart();
    }
    // Called by the bar owner on every (re)open: the island survives closes, so a leaveTimer
    // armed before the last close must not shut the fresh session after the reveal-out delay.
    function cancelPendingHide() {
        leaveTimer.stop();
    }
    Timer {
        id: leaveTimer
        interval: Settings.revealOutPressure
        onTriggered: {
            if (!BarState.tourHoldFor(root.monitorName) && !Settings.panelLockFor("left", root.monitorName) && !islandHover.hovered && !(root.activeWidget && root.activeWidget.popupHovered))
                BarState.deactivate("left", root.monitorName);
        }
    }

    // Esc dismiss once the surface has focus (click a control first).
    IslandEscClose {
        states: ["left"]
        monitorName: root.monitorName
    }

    IslandExpandClip {
        expand: root.expand
        contentHeight: bodyRow.height
        anchors.top: Settings.barOrientation ? parent.top : undefined
        anchors.bottom: Settings.barOrientation ? undefined : parent.bottom

        Row {
            id: bodyRow
            width: parent.width
            height: root.bodyHeight
            spacing: 0

            // Left sidebar with widget selectors
            Rectangle {
                id: sidebar
                width: 48
                height: parent.height
                color: Theme.bg
                // Square on the screen-edge side so the rail runs flush
                // into the panel's edge (mirrors bar orientation).
                topLeftRadius: Settings.barOrientation ? 0 : Theme.radius
                topRightRadius: Settings.barOrientation ? 0 : Theme.radius
                bottomLeftRadius: Settings.barOrientation ? Theme.radius : 0
                bottomRightRadius: Settings.barOrientation ? Theme.radius : 0
                clip: true

                // Widget selector rail (shared component: tab order,
                // icons and tooltips preserved).
                IslandSideRail {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Theme.pad
                    highlightedName: BarState.tourHighlightMonitor === root.monitorName ? BarState.tourHighlightTab : ""
                    // Tab order + icons: Settings, CustomScripts,
                    // KeyBinds ("Widget" suffix for IPC).
                    model: [
                        {
                            name: "SettingsWidget",
                            icon: Icons.settings
                        },
                        {
                            name: "CustomScripts",
                            icon: Icons.terminal
                        },
                        {
                            name: "KeyBinds",
                            icon: Icons.keyboard
                        }
                    ]
                    currentIndex: root.tabIndex(root.selectedWidget)
                    onSelected: index => {
                        root.selectedWidget = root.tabOrder[index];
                    }
                }
                // WindowActions: bottom cluster (valign END, shared).
                IslandWindowActions {
                    side: "left"
                    monitorName: root.monitorName
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Theme.pad
                }
            }

            // Main content area
            Item {
                id: contentArea
                width: parent.width - sidebar.width
                height: parent.height

                // Each tab activates on first select and stays alive, so switches preserve
                // scroll/page state; only the selected one instantiates. Order matches the rail.
                OpacityAnimator on opacity {
                    id: switchAnim
                    from: 0
                    to: 1
                    duration: Theme.anim.large
                    easing.type: Easing.OutCubic
                }
                StackLayout {
                    id: widgetStack
                    anchors.fill: parent
                    // Content inset owned by the panel (right-panel parity) — tab bodies stay
                    // flush and never add their own outer margin.
                    anchors.margins: Theme.pad
                    currentIndex: {
                        switch (root.selectedWidget) {
                        case "SettingsWidget":
                            return 0;
                        case "CustomScripts":
                            return 1;
                        case "KeyBinds":
                            return 2;
                        default:
                            return 0;
                        }
                    }
                    Loader {
                        id: settingsLoader
                        active: root.tabPrimed("SettingsWidget")
                        sourceComponent: settingsComp
                        asynchronous: true
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                    Loader {
                        id: scriptsLoader
                        active: root.tabPrimed("CustomScripts")
                        sourceComponent: scriptsComp
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                    Loader {
                        id: keybindsLoader
                        active: root.tabPrimed("KeyBinds")
                        sourceComponent: keybindsComp
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
                Component {
                    id: settingsComp
                    SettingsWidget {
                        monitorName: root.monitorName
                    }
                }
                Component {
                    id: scriptsComp
                    CustomScriptsWidget {
                        monitorName: root.monitorName
                    }
                }
                Component {
                    id: keybindsComp
                    KeyBindsWidget {}
                }
            }
        }
    }
}
