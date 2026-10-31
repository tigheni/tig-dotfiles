import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.theme
import qs.widgets.shared
import qs.services

// Settings Widget — shell settings panel. Sections run Bar → Screenshots plus
// the Apply/Reset footer; order must match `categories` below.
Item {
    id: root
    property int widgetWidth: parent.width
    property string className: ""
    property string monitorName: ""

    // Single source of truth for rail labels and section headers; order MUST
    // match the CategorySection order below.
    readonly property var categories: [
        { key: "bar", title: "Bar" },
        { key: "panels", title: "Panels" },
        { key: "theme", title: "Theme" },
        { key: "interface", title: "Interface" },
        { key: "animations", title: "Animations" },
        { key: "user-agents", title: "User Agents" },
        { key: "api-keys", title: "API Keys" },
        { key: "reset", title: "Reset" },
        { key: "lockscreen", title: "Lockscreen" },
        { key: "screenshots", title: "Screenshots" },
        { key: "keybinds", title: "Keybinds" }
    ]

    // Island motion-style choices live at root: the shared CategorySection has
    // no per-section property bag.
    readonly property var islandAnimStyleValues: ["Standard", "Emphasized", "ExpressiveFast", "ExpressiveDefault", "ExpressiveSlow"]
    readonly property var islandAnimStyleLabels: ["Standard (smooth)", "Emphasized (smooth)", "Bouncy Fast", "Bouncy Default", "Bouncy Slow"]

    // Unified entrance fade (StackLayout builds tabs hidden): the whole page
    // fades in once, replacing the old per-section stagger.
    property real revealOpacity: 0
    Anim {
        id: revealFade
        target: root
        property: "revealOpacity"
        from: 0
        to: 1
        type: Anim.DefaultEffects
    }
    function playReveal() {
        revealFade.restart();
    }

    // Shared category navigation (rail highlight, centered scroll, distance
    // focus). The sections below bind to this controller.
    CategoryNav {
        id: nav
        flickable: settingsScroll
        content: settingsCol
        categories: root.categories
    }

    // 104 keeps the longest label ("Screenshots") unelided at the
    // default type scale while costing the content column only 30%.
    readonly property int sidebarWidth: 104

    onVisibleChanged: {
        if (visible) {
            root.playReveal();
            root.handlePendingTarget();
        } else {
            // Closed: drop the focus pattern so a reopen is normal. The
            // sidebar keeps the last category selected.
            nav.clearFocus();
        }
    }

    // `visible` is effective here: hiding the island does not emit
    // visibleChanged, so the close cleanup keys off BarState instead.
    Connections {
        target: BarState
        function onPanelStatesByMonitorChanged() {
            if (!BarState.isOpenFor("left", root.monitorName))
                nav.clearFocus();
        }
    }

    // Cross-widget deep link (Registry.selectLeftTab `target`): scrolls the
    // matching apiKeyRepeater row into view and flashes it.
    function handlePendingTarget() {
        const key = Registry.takePendingTarget(root.monitorName);
        if (key === "")
            return;
        // Rows aren't laid out on the first visible frame; defer so
        // mapToItem/contentHeight are accurate.
        Qt.callLater(() => root.scrollToAndHighlight(key));
    }
    Connections {
        target: Registry
        function onPendingTargetsChanged() {
            if (root.visible)
                root.handlePendingTarget();
        }
    }

    function scrollToAndHighlight(key) {
        for (let i = 0; i < apiKeyRepeater.count; i++) {
            const item = apiKeyRepeater.itemAt(i);
            if (!item || item.objectName !== key)
                continue;
            const y = item.mapToItem(settingsCol, 0, 0).y;
            // Keep the rail and the fade anchored on where the deep link
            // landed; the flash is the highlight, not a nav target.
            nav.activeIndex = nav.indexForY(y);
            nav.focusIndex = nav.activeIndex;
            nav.scrollToY(y - 24, -1);
            if (item.flash)
                item.flash();
            return;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing
        opacity: root.revealOpacity

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing
            Label {
                text: "Settings"
                font.pixelSize: Theme.fontSize + 4
                font.bold: true
                color: Theme.fg
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacing

            // Persistent category rail: fixed while the content scrolls.
            CategoryRail {
                Layout.preferredWidth: root.sidebarWidth
                Layout.alignment: Qt.AlignTop
                nav: nav
                model: root.categories
                currentIndex: nav.activeIndex
                onSelected: index => nav.select(index)
            }

            SmoothFlickable {
                id: settingsScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: settingsCol.height
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    // Dragging the bar is a manual scroll: stop an in-flight
                    // category animation so the two never fight over contentY.
                    onPressedChanged: {
                        if (pressed)
                            nav.cancel();
                    }
                }

                Column {
                    id: settingsCol
                    spacing: Theme.spacing
                    width: settingsScroll.width
                    // No edge padding: the panel owns the content inset (the
                    // island's Theme.pad), right-panel parity.

                    // ============ BAR SETTINGS ============
                    // Always all sections; visibility only via SUPER+ALT+BACKSPACE IPC.
                    CategorySection {
                        nav: nav
                        categoryIndex: 0

                        SettingRow {
                            text: "Orientation"
                            tip: "Top or bottom edge for the bar."
                            AppComboBox {
                                model: ["Top", "Bottom"]
                                currentIndex: Settings.barOrientation ? 0 : 1
                                onActivated: Settings.barOrientation = (index === 0)
                                Layout.preferredWidth: 160
                            }
                        }
                    }

                    // ============ PANEL SETTINGS ============
                    CategorySection {
                        nav: nav
                        categoryIndex: 1

                        SettingRow {
                            text: "Left Panel Width"
                            tip: "Width of the left side panel on this monitor in px."
                            AppSpinBox {
                                from: 200
                                to: 1500
                                value: Settings.panelWidthFor("left", root.monitorName)
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (value === Settings.panelWidthFor("left", root.monitorName))
                                        return;
                                    Settings.setPanelWidthFor("left", root.monitorName, value);
                                }
                            }
                        }
                        SettingRow {
                            text: "Right Panel Width"
                            tip: "Width of the right side panel on this monitor in px."
                            AppSpinBox {
                                from: 200
                                to: 1500
                                value: Settings.panelWidthFor("right", root.monitorName)
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (value === Settings.panelWidthFor("right", root.monitorName))
                                        return;
                                    Settings.setPanelWidthFor("right", root.monitorName, value);
                                }
                            }
                        }
                        SettingRow {
                            text: "Left Panel Hot Zone"
                            tip: "Hover the left edge to open the left panel."
                            AppToggle {
                                checked: Settings.leftPanelHotZone
                                onToggled: Settings.leftPanelHotZone = checked
                            }
                        }
                        SettingRow {
                            text: "Right Panel Hot Zone"
                            tip: "Hover the right edge to open the right panel."
                            AppToggle {
                                checked: Settings.rightPanelHotZone
                                onToggled: Settings.rightPanelHotZone = checked
                            }
                        }
                        SettingRow {
                            text: "Left Hot Zone Size"
                            tip: "Hover strip width on the left edge in px."
                            AppSpinBox {
                                from: 1
                                to: 50
                                value: Settings.leftPanelHotZoneSize
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (value === Settings.leftPanelHotZoneSize)
                                        return;
                                    Settings.leftPanelHotZoneSize = value;
                                }
                            }
                        }
                        SettingRow {
                            text: "Right Hot Zone Size"
                            tip: "Hover strip width on the right edge in px."
                            AppSpinBox {
                                from: 1
                                to: 50
                                value: Settings.rightPanelHotZoneSize
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (value === Settings.rightPanelHotZoneSize)
                                        return;
                                    Settings.rightPanelHotZoneSize = value;
                                }
                            }
                        }
                        AppButton {
                            text: "Preview Hot Zones"
                            tooltipText: "Flash the edge hover areas on screen."
                            onClicked: root.previewHotZones()
                        }
                    }

                    // ============ THEME SETTINGS ============
                    CategorySection {
                        nav: nav
                        categoryIndex: 2

                        SettingRow {
                            text: "Dynamic Theme Colors"
                            tip: "Recolor the theme from the wallpaper."
                            AppToggle {
                                checked: Settings.dynamicThemeColors
                                onToggled: {
                                    Settings.dynamicThemeColors = checked;
                                    root.setThemeFlagInConf("autocolor", checked);
                                }
                            }
                        }
                        SettingRow {
                            text: "Dynamic Theme Variants"
                            tip: "Switch light/dark variant from wallpaper."
                            AppToggle {
                                checked: Settings.dynamicThemeVariants
                                onToggled: {
                                    Settings.dynamicThemeVariants = checked;
                                    root.setThemeFlagInConf("autovariant", checked);
                                }
                            }
                        }
                        SettingRow {
                            text: "Radius"
                            tip: "Corner radius for pills, cards and panels."
                            AppSpinBox {
                                from: 0
                                to: 24
                                value: Settings.uiRadius
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (value === Settings.uiRadius)
                                        return;
                                    Settings.uiRadius = value;
                                }
                            }
                        }
                        SettingRow {
                            text: "Pad (Inset)"
                            tip: "Content inset inside cards, panels and islands."
                            AppSpinBox {
                                from: 0
                                to: 16
                                value: Settings.uiPad
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (value === Settings.uiPad)
                                        return;
                                    Settings.uiPad = value;
                                }
                            }
                        }
                        SettingRow {
                            text: "Spacing"
                            tip: "Gap between bar elements and stacked sections."
                            AppSpinBox {
                                from: 2
                                to: 16
                                value: Settings.uiSpacing
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (value === Settings.uiSpacing)
                                        return;
                                    Settings.uiSpacing = value;
                                }
                            }
                        }
                    }

                    // ============ INTERFACE ============
                    CategorySection {
                        nav: nav
                        categoryIndex: 3

                        SettingRow {
                            text: "Opacity"
                            tip: "Shell opacity; 1 is fully opaque."
                            AppSlider {
                                from: 0
                                to: 1
                                value: Settings.uiOpacity
                                stepSize: 0.01
                                // Fill: the value label fixes the right edge; a
                                // fixed 150 starved the row label.
                                Layout.fillWidth: true
                                onValueChanged: {
                                    if (value === Settings.uiOpacity)
                                        return;
                                    Settings.uiOpacity = value;
                                }
                            }
                            Label {
                                font.pixelSize: Theme.fontSize
                                text: Settings.uiOpacity.toFixed(2)
                                color: Theme.fgDim
                                Layout.preferredWidth: 34
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                        SettingRow {
                            text: "Font Size"
                            tip: "Base font size for shell text."
                            AppSpinBox {
                                from: 10
                                to: 30
                                value: Settings.uiFontSize
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (value === Settings.uiFontSize)
                                        return;
                                    Settings.uiFontSize = value;
                                }
                            }
                        }
                    }

                    // ============ ANIMATIONS ============
                    CategorySection {
                        nav: nav
                        categoryIndex: 4

                        SettingRow {
                            text: "Enabled"
                            tip: "Turn all shell animations on or off."
                            AppToggle {
                                checked: Settings.animationsEnabled
                                onToggled: Settings.animationsEnabled = checked
                            }
                        }
                        SettingRow {
                            text: "Speed"
                            tip: "Duration multiplier; lower is faster."
                            AppSlider {
                                from: 0.2
                                to: 2.0
                                stepSize: 0.05
                                value: Settings.animScale
                                Layout.fillWidth: true
                                onValueChanged: {
                                    const v = Math.round(value * 100) / 100;
                                    if (Math.abs(v - Settings.animScale) < 0.001)
                                        return;
                                    Settings.animScale = v;
                                }
                            }
                            Label {
                                font.pixelSize: Theme.fontSize
                                text: Settings.animScale.toFixed(2) + "×"
                                color: Theme.fgDim
                                Layout.preferredWidth: 44
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "Lower is faster (duration multiplier)."
                            color: Theme.fgDim
                            font.pixelSize: Theme.fontSize - 1
                        }
                        SettingRow {
                            text: "Island Style"
                            tip: "Motion style used by bar islands."
                            AppComboBox {
                                model: root.islandAnimStyleLabels
                                currentIndex: Math.max(0, root.islandAnimStyleValues.indexOf(Settings.islandAnimStyle))
                                onActivated: Settings.islandAnimStyle = root.islandAnimStyleValues[index]
                                Layout.preferredWidth: 160
                            }
                        }
                        SettingRow {
                            text: "Reveal-In Pressure"
                            tip: "Hover dwell before a bar pill or island reveals."
                            AppSpinBox {
                                from: 0
                                to: 5000
                                value: Settings.revealInPressure
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (value === Settings.revealInPressure)
                                        return;
                                    Settings.revealInPressure = value;
                                }
                            }
                        }
                        SettingRow {
                            text: "Reveal-Out Pressure"
                            tip: "Delay before a hovered island closes."
                            AppSpinBox {
                                from: 0
                                to: 5000
                                value: Settings.revealOutPressure
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (value === Settings.revealOutPressure)
                                        return;
                                    Settings.revealOutPressure = value;
                                }
                            }
                        }
                    }

                    // ============ USER AGENTS ============
                    CategorySection {
                        nav: nav
                        categoryIndex: 5

                        Repeater {
                            model: [
                                { key: "booru", label: "Booru" },
                                { key: "mangaDex", label: "MangaDex" },
                                { key: "mangaLib", label: "MangaLib" },
                                { key: "waifu", label: "Waifu" },
                                { key: "fastfetch", label: "Fastfetch" }
                            ]
                            delegate: Rectangle {
                                width: parent.width
                                height: uaRow.implicitHeight
                                color: "transparent"

                                property bool reveal: false

                                RowLayout {
                                    id: uaRow
                                    width: parent.width
                                    spacing: Theme.spacing
                                    SettingLabel {
                                        text: modelData.label
                                        tip: "Custom User-Agent sent with " + modelData.label + " requests."
                                        // Share the row with the field: a fixed 90
                                        // left it ~30px once the rail took its width.
                                        Layout.fillWidth: true
                                    }
                                    AppTextField {
                                        id: uaField
                                        text: Settings.userAgent(modelData.key)
                                        placeholderText: "User-Agent"
                                        echoMode: parent.parent.reveal ? TextField.Normal : TextField.Password
                                        fillColor: "transparent"
                                        Layout.fillWidth: true
                                        onAccepted: {
                                            const u = JSON.parse(JSON.stringify(Settings.userAgents || {}));
                                            u[modelData.key] = uaField.text;
                                            Settings.userAgents = u;
                                            Settings.schedulePersist();
                                        }
                                    }
                                    AppButton {
                                        text: parent.parent.reveal ? "hide" : "show"
                                        Layout.preferredWidth: 44
                                        Layout.preferredHeight: 24
                                        visible: uaField.text !== ""
                                        tooltipText: "Show or hide the value"
                                        onClicked: parent.parent.reveal = !parent.parent.reveal
                                    }
                                    AppButton {
                                        text: "copy"
                                        Layout.preferredWidth: 44
                                        Layout.preferredHeight: 24
                                        visible: uaField.text !== ""
                                        tooltipText: "Copy the value to the clipboard"
                                        onClicked: root.copyText(uaField.text)
                                    }
                                }
                            }
                        }
                    }

                    // ============ API KEYS ============
                    CategorySection {
                        nav: nav
                        categoryIndex: 6

                        Repeater {
                            id: apiKeyRepeater
                            model: [
                                {
                                    path: "danbooru.user",
                                    label: "Danbooru User"
                                },
                                {
                                    path: "danbooru.key",
                                    label: "Danbooru Key"
                                },
                                {
                                    path: "gelbooru.user",
                                    label: "Gelbooru User"
                                },
                                {
                                    path: "gelbooru.key",
                                    label: "Gelbooru Key"
                                },
                                {
                                    path: "safebooru.user",
                                    label: "Safebooru User"
                                },
                                {
                                    path: "safebooru.key",
                                    label: "Safebooru Key"
                                },
                                {
                                    path: "wallhaven.key",
                                    label: "Wallhaven Key (optional, unlocks NSFW)"
                                }
                            ]
                            delegate: Rectangle {
                                id: keyRow
                                // NOTE: Repeater has no width — size off the
                                // section Column instead.
                                width: parent.width
                                height: keyRowLayout.implicitHeight
                                color: "transparent"
                                radius: Theme.radius
                                objectName: modelData.path

                                property bool reveal: false

                                border.color: Theme.accent
                                border.width: 0
                                function flash() {
                                    flashAnim.restart();
                                }
                                SequentialAnimation {
                                    id: flashAnim
                                    loops: 2
                                    NumberAnimation {
                                        target: keyRow
                                        property: "border.width"
                                        from: 0
                                        to: 2
                                        duration: Theme.anim.small
                                        easing.type: Easing.OutCubic
                                    }
                                    NumberAnimation {
                                        target: keyRow
                                        property: "border.width"
                                        from: 2
                                        to: 0
                                        duration: Theme.anim.defaultSpatial
                                        easing.type: Easing.InCubic
                                    }
                                }

                                RowLayout {
                                    id: keyRowLayout
                                    width: parent.width
                                    spacing: Theme.spacing
                                    SettingLabel {
                                        text: modelData.label
                                        tip: root.apiKeyTip(modelData.path, modelData.label)
                                        Layout.fillWidth: true
                                    }

                                    AppTextField {
                                        id: keyField
                                        text: root.getNested(Settings.apiKeys, modelData.path)
                                        placeholderText: "Enter " + modelData.label
                                        echoMode: parent.parent.reveal ? TextField.Normal : TextField.Password
                                        fillColor: "transparent"
                                        // Fill: this dense row also carries
                                        // show/copy buttons, so a fixed 160 overflowed.
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 48
                                        onAccepted: {
                                            root.setNestedValue("apiKeys", modelData.path, keyField.text, true);
                                            // Notify masked value on save (secret)
                                            Notifications.notify({
                                                summary: modelData.label,
                                                body: "Changed to ••••••••"
                                            });
                                        }
                                    }
                                    AppButton {
                                        text: parent.parent.reveal ? "hide" : "show"
                                        Layout.preferredWidth: 44
                                        Layout.preferredHeight: 24
                                        visible: keyField.text !== ""
                                        tooltipText: "Show or hide the key"
                                        onClicked: parent.parent.reveal = !parent.parent.reveal
                                    }
                                    AppButton {
                                        text: "copy"
                                        Layout.preferredWidth: 44
                                        Layout.preferredHeight: 24
                                        tooltipText: "Copy the key to the clipboard"
                                        onClicked: root.copyText(keyField.text)
                                    }
                                }
                            }
                        }
                    }

                    // ============ RESET ============
                    // (ArchEclipse's Hyprland look controls are left out: window
                    // gaps, rounding and blur stay owned by config/hypr.)
                    CategorySection {
                        nav: nav
                        categoryIndex: 7

                        Column {
                            width: parent.width
                            spacing: Theme.spacing
                            AppButton {
                                width: parent.width
                                text: "Reset to Default"
                                tooltipText: "Restore all settings to defaults."
                                onClicked: root.resetToDefaults()
                            }
                        }
                    }

                    // ============ LOCKSCREEN ============
                    CategorySection {
                        nav: nav
                        categoryIndex: 8

                        SettingRow {
                            text: "Grace Period (seconds)"
                            tip: "Time Esc unlocks without a password."
                            AppSpinBox {
                                from: 0
                                to: 120
                                value: Settings.lockGraceSeconds
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (value === Settings.lockGraceSeconds)
                                        return;
                                    Settings.lockGraceSeconds = value;
                                }
                            }
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "Esc dismisses the lock without a password within this window after locking."
                            color: Theme.fgDim
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }

                    // ============ SCREENSHOT SETTINGS ============
                    CategorySection {
                        nav: nav
                        categoryIndex: 9

                        SettingRow {
                            text: "Directory to save screenshots"
                            tip: "Screenshots are stored in fullscreen/ and area/ subfolders. You can use an absolute path or ~/…"
                            labelWidth: 150
                            AppTextField {
                                Layout.fillWidth: true
                                placeholderText: Quickshell.env("HOME") + "/Pictures/Screenshots"
                                text: root.screenshotValue("directory")
                                onEditingFinished: {
                                    root.setScreenshotSetting("directory", text.trim());
                                    text = Qt.binding(() => root.screenshotValue("directory"));
                                }
                            }
                        }
                        SettingRow {
                            text: "Image format"
                            tip: "PNG is lossless. JPEG makes smaller files using lossy compression."
                            labelWidth: 150
                            AppComboBox {
                                model: root.screenshotFormatOptions
                                textRole: "name"
                                Layout.fillWidth: true
                                currentIndex: root.optionIndex(root.screenshotFormatOptions, root.screenshotValue("format"))
                                onActivated: index => root.setScreenshotSetting("format", root.screenshotFormatOptions[index].value)
                            }
                        }
                        SettingRow {
                            visible: root.screenshotValue("format") === "jpeg"
                            text: "JPEG quality"
                            tip: "Higher values preserve more detail and create larger files (0–100)."
                            labelWidth: 150
                            AppSpinBox {
                                from: 0
                                to: 100
                                value: root.screenshotValue("jpegQuality")
                                Layout.preferredWidth: 120
                                onValueChanged: {
                                    if (value !== root.screenshotValue("jpegQuality"))
                                        root.setScreenshotSetting("jpegQuality", value);
                                }
                            }
                        }
                        SettingRow {
                            visible: root.screenshotValue("format") === "png"
                            text: "PNG compression"
                            tip: "Higher levels reduce file size but can take longer; image quality stays lossless (0–9)."
                            labelWidth: 150
                            AppSpinBox {
                                from: 0
                                to: 9
                                value: root.screenshotValue("pngCompression")
                                Layout.preferredWidth: 120
                                onValueChanged: {
                                    if (value !== root.screenshotValue("pngCompression"))
                                        root.setScreenshotSetting("pngCompression", value);
                                }
                            }
                        }
                        SettingRow {
                            text: "Optimize PNG"
                            visible: root.screenshotValue("format") === "png"
                            tip: "Run ImageMagick to strip metadata and recompress the PNG. This can take longer."
                            labelWidth: 150
                            AppToggle {
                                checked: root.screenshotValue("optimizePng")
                                onToggled: root.setScreenshotSetting("optimizePng", checked)
                            }
                        }
                        SettingRow {
                            text: "Include cursor"
                            tip: "Capture the mouse cursor in the screenshot."
                            labelWidth: 150
                            AppToggle {
                                checked: root.screenshotValue("includeCursor")
                                onToggled: root.setScreenshotSetting("includeCursor", checked)
                            }
                        }
                        SettingRow {
                            text: "Copy to clipboard"
                            tip: "Copy the image, or a list of image files when capturing all monitors."
                            labelWidth: 150
                            AppToggle {
                                checked: root.screenshotValue("copyToClipboard")
                                onToggled: root.setScreenshotSetting("copyToClipboard", checked)
                            }
                        }
                        SettingRow {
                            text: "Show notification"
                            tip: "Show a desktop notification after a screenshot is saved."
                            labelWidth: 150
                            AppToggle {
                                checked: root.screenshotValue("notifyOnSave")
                                onToggled: root.setScreenshotSetting("notifyOnSave", checked)
                            }
                        }
                        SettingRow {
                            text: "Freeze during area selection"
                            tip: "Use hyprpicker to freeze the screen while choosing a region."
                            labelWidth: 150
                            AppToggle {
                                checked: root.screenshotValue("freezeOnArea")
                                onToggled: root.setScreenshotSetting("freezeOnArea", checked)
                            }
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "PNG is lossless; JPEG trades image detail for smaller files. Settings apply to the next capture."
                            color: Theme.fgDim
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }

                    // ============ KEYBINDS ============
                    CategorySection {
                        nav: nav
                        categoryIndex: 10

                        SettingRow {
                            text: "Super key symbol"
                            tip: "Choose the glyph used for the Super / Windows modifier."

                            AppComboBox {
                                model: [Icons.keySuperArch, Icons.keySuperManjaro, Icons.keySuperEndeavour, Icons.keySuperCachyOS, Icons.keySuperGaruda, Icons.keySuperArchcraft, Icons.keySuperArcoLinux, Icons.keySuperArtix, Icons.keySuperLinuxTerminal, Icons.keySuperLinux, Icons.keySuperGentoo, Icons.keySuperDebian, Icons.keySuperUbuntu, Icons.keySuperRedHat, Icons.keySuperFedora, Icons.keySuperSteam, Icons.keySuperApple, Icons.keySuperCommand, Icons.keySuperAndroid, Icons.keySuperAssistant, Icons.keySuperChrome, Icons.keySuperWindows11, Icons.keySuperWindowsClassic]
                                currentIndex: Math.max(0, model.indexOf(Settings.keybindsSuperKey))
                                onActivated: Settings.keybindsSuperKey = model[index]
                                Layout.preferredWidth: 120
                            }

                        }

                        SettingRow {
                            text: "Use macOS-like mod symbols"
                            tip: "Render Ctrl/Alt/Shift with the classic macOS glyphs."

                            AppToggle {
                                checked: Settings.keybindsUseMacSymbol
                                onToggled: Settings.keybindsUseMacSymbol = checked
                            }

                        }

                        SettingRow {
                            text: "Use symbols for function keys"
                            tip: "Render F1–F12 with Nerd Font glyphs."

                            AppToggle {
                                checked: Settings.keybindsUseFunctionSymbol
                                onToggled: Settings.keybindsUseFunctionSymbol = checked
                            }

                        }

                        SettingRow {
                            text: "Use symbols for mouse"
                            tip: "Render mouse actions and buttons with compact glyphs."

                            AppToggle {
                                checked: Settings.keybindsUseMouseSymbol
                                onToggled: Settings.keybindsUseMouseSymbol = checked
                            }

                        }

                        SettingRow {
                            text: "Split buttons"
                            tip: "Display modifier and key as separate chips."

                            AppToggle {
                                checked: Settings.keybindsSplitButtons
                                onToggled: Settings.keybindsSplitButtons = checked
                            }

                        }

                        SettingRow {
                            text: "Keybind font size"
                            tip: "Size of each key cap in the keybind list."

                            AppSpinBox {
                                from: 8
                                to: 30
                                value: Settings.keybindsFontSize
                                Layout.preferredWidth: 50
                                onValueChanged: {
                                    if (value === Settings.keybindsFontSize)
                                        return ;

                                    Settings.keybindsFontSize = value;
                                }
                            }

                        }

                        SettingRow {
                            text: "Description font size"
                            tip: "Size of the keybind description text."

                            AppSpinBox {
                                from: 8
                                to: 30
                                value: Settings.keybindsDescriptionFontSize
                                Layout.preferredWidth: 50
                                onValueChanged: {
                                    if (value === Settings.keybindsDescriptionFontSize)
                                        return ;

                                    Settings.keybindsDescriptionFontSize = value;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ------- helpers -------

    readonly property var screenshotFormatOptions: [
        { value: "png", name: "PNG (lossless)" },
        { value: "jpeg", name: "JPEG" }
    ]

    function screenshotValue(key) {
        const settings = Settings.screenshot || Settings.defaultScreenshotSettings();
        const value = settings[key];
        return value === undefined || value === null ? Settings.defaultScreenshotSettings()[key] : value;
    }

    function setScreenshotSetting(key, value) {
        const next = Object.assign({}, Settings.screenshot || Settings.defaultScreenshotSettings());
        if (key === "directory")
            value = String(value || "").trim() || Settings.defaultScreenshotSettings().directory;
        next[key] = value;
        Settings.screenshot = next;
        Settings.schedulePersist();
    }

    function optionIndex(options, value) {
        for (let i = 0; i < options.length; i++) {
            if (options[i].value === value)
                return i;
        }
        return 0;
    }

    Component.onCompleted: {
        if (visible)
            root.playReveal();
    }

    // Get nested value from an object by dotted path. Unwraps
    // credential objects ({value: ...}) to plain strings for display.
    function getNested(obj, path) {
        if (!path || !obj)
            return "";
        const keys = path.split(".");
        let o = obj;
        for (const k of keys) {
            if (o == null)
                return "";
            o = o[k];
        }
        if (o == null)
            return "";
        if (typeof o === "object")
            return (o.value ?? "");
        return o;
    }

    // Set nested value by dotted path. persistIfSetting == true for apiKeys group.
    // Preserves credential objects (writes .value, keeps shape on disk).
    function setNestedValue(propRoot, path, value, persist) {
        // propRoot is a Settings property name; navigate from Settings
        const keys = path.split(".");
        let o = Settings[propRoot];
        if (o == null)
            o = {};
        for (let i = 0; i < keys.length - 1; i++) {
            if (o[keys[i]] == null)
                o[keys[i]] = {};
            o = o[keys[i]];
        }
        const leaf = keys[keys.length - 1];
        if (o[leaf] != null && typeof o[leaf] === "object" && "value" in o[leaf])
            o[leaf].value = value;
        else
            o[leaf] = value;
        Settings[propRoot] = JSON.parse(JSON.stringify(Settings[propRoot]));
        if (persist)
            Settings.schedulePersist();
    }

    // Concise tooltip per API-key row (shown via SettingLabel).
    function apiKeyTip(path, label) {
        switch (path) {
        case "danbooru.user":
            return "Your Danbooru login name.";
        case "danbooru.key":
            return "Key for Danbooru favorites and uploads.";
        case "gelbooru.user":
            return "Your Gelbooru login name.";
        case "gelbooru.key":
            return "Key for Gelbooru favorites.";
        case "safebooru.user":
            return "Your Safebooru login name.";
        case "safebooru.key":
            return "Key for Safebooru favorites.";
        case "wallhaven.key":
            return "Optional key; unlocks NSFW wallpapers.";
        default:
            return "Stored locally; used for " + label + ".";
        }
    }

    function copyText(t) {
        Qt.callLater(function () {
            Quickshell.execDetached(["wl-copy", t]);
        });
    }

    // Write autocolor/autovariant flag into the coloreclipse conf
    // (~/.config/coloreclipse/theme.conf)
    function setThemeFlagInConf(flag, enabled) {
        const confPath = root.themeConfPath;
        const val = enabled ? "true" : "false";
        Qt.callLater(function () {
            Quickshell.execDetached(["bash", "-c", `mkdir -p "$(dirname "${confPath}")"
                  if [[ -f "${confPath}" ]]; then
                  sed -i 's/^${flag}=.*/${flag}=${val}/' "${confPath}"
                  grep -q '^${flag}=' "${confPath}" || printf '%s\\n' '${flag}=${val}' >> "${confPath}"
                else
                  printf '%s\\n' '${flag}=${val}' > "${confPath}"
                fi`]);
        });
    }

    property string themeConfPath: Quickshell.env("HOME") + "/.config/coloreclipse/theme.conf"

    function previewHotZones() {
        Qt.callLater(function () {
            Quickshell.execDetached(["hyprctl", "notify", "3", "3000", "rgb(ff9800)", "Hot zones highlighted"]);
        });
    }

    function resetToDefaults() {
        // Leaving the focused-navigation state with the old values would
        // strand the fade over freshly reset sections.
        nav.clearFocus();
        Settings.barSmartHide = false;
        Settings.barFullWidth = false;
        Settings.revealInPressure = 250;
        Settings.revealOutPressure = 1000;
        Settings.barOrientation = true;
        Settings.leftPanelWidth = 400;
        Settings.rightPanelWidth = 250;
        Settings.leftPanelByMonitor = ({});
        Settings.rightPanelByMonitor = ({});
        Settings.leftPanelHotZone = true;
        Settings.rightPanelHotZone = true;
        Settings.leftPanelHotZoneSize = 5;
        Settings.rightPanelHotZoneSize = 5;
        Settings.dynamicThemeColors = false;
        Settings.dynamicThemeVariants = false;
        Settings.uiOpacity = 0.618;
        Settings.uiRadius = 12;
        Settings.uiPad = 8;
        Settings.uiSpacing = 8;
        Settings.uiFontSize = 12;
        Settings.animationsEnabled = true;
        Settings.animScale = 1.0;
        Settings.islandAnimStyle = "Emphasized";
        Settings.screenshot = Settings.defaultScreenshotSettings();
        Settings.recording = Settings.defaultRecordingSettings();
        Settings.schedulePersist();
    }
}
