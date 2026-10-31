import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services
import qs.widgets.shared

// Pick a wallpaper (applied on every monitor via set-wallpaper.sh), browse/add/delete; hosted by
// WallpaperIsland in the main pill. Previews render the original files, no thumbnails.
Item {
    id: root

    // Island owner passes the bar's monitor; falls back to focused.
    property string monitorName: ""
    readonly property string effectiveMonitor: root.monitorName || Registry.monitorName

    // No implicitWidth: the host owns the width (the bar reads the island's implicitWidth), so
    // a value here is inert. Height is content-driven — mainCol has no margin, so its is the body's.
    implicitHeight: mainCol.implicitHeight

    readonly property string home: Quickshell.env("HOME")
    readonly property string dotfilesDir: Quickshell.env("DOTFILES_DIR")
    // Where imports and wallhaven downloads land (the "Pictures" category).
    readonly property string wallpapersDir: home + "/Pictures/Wallpapers"

    function isVideoFile(file) {
        return WallpaperService.isVideoFile(file);
    }

    function isGifFile(file) {
        return /\.gif$/i.test(String(file || ""));
    }

    function isAnimatedPreviewFile(file) {
        return root.isVideoFile(file) || root.isGifFile(file);
    }

    // ---------------------------------------------------------------- state

    // Current wallpaper: one absolute path, written by set-wallpaper.sh (realpath'd, so a
    // file under the symlinked ~/.config/hypr is recorded with its dotfiles-repo path).
    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/wallpaper"
    property string currentWallpaper: ""
    function isCurrentWallpaper(path) {
        const cur = root.currentWallpaper;
        if (cur === "" || path === undefined)
            return false;
        if (cur === path)
            return true;
        // Same file reached through the symlinked hypr dir: compare the tail past it.
        const key = "/hypr/wallpaper/";
        const a = cur.lastIndexOf(key), b = String(path).lastIndexOf(key);
        return a !== -1 && b !== -1 && cur.slice(a) === String(path).slice(b);
    }
    FileView {
        id: currentFile
        path: root.stateFile
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.currentWallpaper = text().trim()
        onLoadFailed: root.currentWallpaper = ""
    }

    // Phased progress label (no spinner): searching/downloading/setting/deleting/adding and so
    // on; success and error auto-reset to idle after 1.5s.
    property string progressStatus: "idle"
    readonly property string progressText: {
        switch (root.progressStatus) {
        case "searching":
            return "Searching…";
        case "downloading":
            return "Downloading…";
        case "setting":
            return "Setting…";
        case "deleting":
            return "Deleting…";
        case "adding":
            return "Adding…";
        case "reloading":
            return "Reloading…";
        case "loading":
            return "Working…";
        case "success":
            return "Done";
        case "error":
            return "Failed";
        default:
            return "";
        }
    }
    readonly property string progressColor: {
        if (root.progressStatus === "success")
            return Theme.fg;
        if (root.progressStatus === "error")
            return Theme.color1;
        if (root.progressStatus === "idle")
            return Theme.fgDim;
        return Theme.accent;
    }
    function setProgress(status) {
        progressStatus = status;
        if (status === "success" || status === "error")
            progressResetTimer.restart();
    }
    Timer {
        id: progressResetTimer
        interval: 1500
        onTriggered: root.progressStatus = "idle"
    }

    // Shared store fetched at boot: WallpaperService owns the category map, thumb manifest and
    // aspect cache, and this body binds read-only so every monitor shares one scan.
    readonly property var wallpapers: WallpaperService.wallpapers
    readonly property var categories: Object.keys(wallpapers)
    // Single source of truth: Settings.wallpaperCategory, never assigned locally so it cannot
    // desync — writers go through Settings.updateSetting and every reader follows the binding.
    readonly property string selectedCategory: Settings.wallpaperCategory
    // Self-heal a saved category whose dir was deleted, gated on ready + non-empty so a fast
    // fetch cannot clobber the saved value before Settings.reload() adopts the file.
    function validateCategory() {
        if (!Settings.ready || root.categories.length === 0)
            return;
        if (!root.categories.includes(Settings.wallpaperCategory))
            Settings.updateSetting("wallpaperSwitcher.category", root.categories[0]);
    }
    // ComboBox resets currentIndex on model replacement (breaking any binding), so re-sync
    // imperatively, deferred past its own model-reset handling.
    function syncCategoryCombo() {
        Qt.callLater(() => {
            const i = root.categories.indexOf(root.selectedCategory);
            if (categoryCombo.currentIndex !== i)
                categoryCombo.currentIndex = i;
        });
    }
    Connections {
        target: Settings
        function onWallpaperCategoryChanged() {
            root.validateCategory();
            root.syncCategoryCombo();
        }
    }
    onCategoriesChanged: {
        root.validateCategory();
        root.syncCategoryCombo();
    }
    readonly property var selectedWallpapers: wallpapers[selectedCategory] ?? []
    // Capture must wait for data/thumbnail generation and masonry aspect updates;
    // CaptureIpc separately checks instantiated tiles (including opacity-zero ones).
    readonly property bool captureReady: !WallpaperService.fetchProc.running && !WallpaperService.thumbProc.running && !WallpaperService._thumbPending && !whLoading && Object.keys(WallpaperService._pendingAspect).length === 0 && (progressStatus === "idle" || progressStatus === "success") && (isWallhaven ? whResults.length > 0 : selectedWallpapers.length > 0)
    // Exposed for Ipc wallpaperDiag ("strip" query) and tests.
    readonly property alias wallStrip: wallScroll
    // Test hook for the "stripdeep" diag: lets automation walk the local
    // masonry geometry (rows, cellX/cellW, inWindow) without a mouse.
    readonly property alias localMasonry: localMasonry

    // ------------------------------------------------- provider abstraction
    // "local" reuses the folder categories; "wallhaven" downloads into wallpapersDir, same pipeline.
    readonly property var providerTypes: ["local", "wallhaven"]
    readonly property string provider: Settings.wallpaperProvider
    readonly property var wh: Settings.wallpaperWallhaven
    readonly property string whApiKey: Settings.apiKey("wallhaven", "key")
    readonly property bool isWallhaven: root.provider === "wallhaven"

    // Shared masonry (both providers): exact results height from rows × tile height plus gaps;
    // tile widths come from aspect ratios, never the viewport.
    readonly property real resultsH: Math.max(1, Settings.wallpaperMasonryRows) * Settings.wallpaperTileSize + (Math.max(1, Settings.wallpaperMasonryRows) - 1) * 6
    function setMasonryRows(n) {
        Settings.updateSetting("wallpaperSwitcher.masonryRows", Math.min(4, Math.max(1, n)));
    }
    // Decoded-aspect cache in the shared store, reassigned (not mutated) so the masonry
    // recomputes; unknown paths fall back to 16:9 and settle once their thumb decodes.
    readonly property var localAspect: WallpaperService.localAspect
    function localAspectOf(path) {
        return WallpaperService.localAspectOf(path);
    }
    // Batched aspect reports live in the service (thumbs decode in a
    // storm on open); the service adopts once 250ms after last report.
    readonly property var _pendingAspect: WallpaperService._pendingAspect
    function noteLocalAspect(path, ratio) {
        WallpaperService.noteLocalAspect(path, ratio);
    }
    // Wallhaven aspects are known up-front from the resolution string.
    function whAspect(item) {
        const m = String((item && item.resolution) || "").split("x");
        const w = parseFloat(m[0]), h = parseFloat(m[1]);
        return (w > 0 && h > 0) ? w / h : 16 / 9;
    }

    readonly property string wallhavenScript: home + "/.config/quickshell/archeclipse/scripts/wallhaven.py"

    // First-frame thumbnails for video tiles live in the shared store
    // (adopted from WallpaperService's background ffmpeg queue).
    readonly property var thumbMap: WallpaperService.thumbMap
    function thumbFor(path) {
        return WallpaperService.thumbFor(path);
    }

    // Wallhaven filter option models (static; index-synced like categoryCombo).
    // atleast/ratios use "Any" as the display label for the empty (omit) value.
    readonly property var whSortingItems: ["date_added", "relevance", "random", "views", "favorites", "toplist"]
    readonly property var whCategoryNames: ["General", "Anime", "People"]
    readonly property var whOrderItems: ["desc", "asc"]
    readonly property var whTopRangeItems: ["1d", "3d", "1w", "1M", "3M", "6M", "1y"]
    readonly property var whAtleastItems: ["Any", "1920x1080", "2560x1440", "3840x2160"]
    readonly property var whRatioItems: ["Any", "16x9", "16x10", "21x9", "9x16", "1x1", "4x3", "32x9"]
    function whMapped(v, items) {
        return (v === "" ? items[0] : v);
    }
    function whUnmap(v, items) {
        return (v === items[0] ? "" : v);
    }

    // Read-modify-write one Wallhaven filter through updateSetting (new identity so the binding
    // re-evaluates). Filter edits reset to page 1 and debounce; page turns search immediately.
    function setWh(key, value, immediate) {
        const next = Object.assign({}, root.wh);
        next[key] = value;
        if (key !== "page")
            next.page = 1;
        Settings.updateSetting("wallpaperSwitcher.wallhaven", next);
        if (immediate)
            root.whSearch();
        else
            whDebounce.restart();
    }

    property var whResults: []
    property var whMeta: ({
            page: 1,
            per_page: 24,
            total: 0,
            last_page: 1,
            seed: ""
        })
    property bool whLoading: false
    property int _whSeq: 0
    property string _whErr: ""
    property string _whDownloadedPath: ""
    property string _pendingWhApply: "" // "apply" | "" (save only)
    Timer {
        id: whDebounce
        interval: 400
        onTriggered: root.whSearch()
    }
    // Key added/removed while browsing: a removed key must drop an NSFW
    // purity the guest API would 401 on; either way re-run the search.
    onWhApiKeyChanged: {
        if (!root.isWallhaven)
            return;
        if (root.whApiKey === "" && root.wh.purity.charAt(2) === "1")
            root.setWh("purity", "100");
        else
            root.whSearch();
    }
    onProviderChanged: {
        // NOTE: read root.provider, NOT isWallhaven — dependent bindings re-evaluate after change
        // handlers, so isWallhaven still holds the old value. force=true skips whSearch's guard.
        if (root.provider === "wallhaven")
            root.whSearch(true);
    }

    Component.onCompleted: {
        // Shared store is primed at shell boot; ensure it here too for
        // island-first creation paths.
        WallpaperService.start();
        if (root.isWallhaven)
            root.whSearch();
    }

    // Hosts call this when the body becomes visible.
    function refresh() {
        WallpaperService.refresh();
        currentFile.reload();
        if (root.isWallhaven)
            root.whSearch();
    }

    function notifyError(context, err) {
        setProgress("error");
        console.warn("[WallpaperSwitcher]", context, err);
        Notifications.notify({
            summary: "Error",
            body: String(err)
        }); // adjust to your notify service
    }

    // ---------------------------------------------------------- data fetch
    // Category map + thumbs come from WallpaperService (boot); this body keeps only the current path.
    function fetchWallpapers() {
        WallpaperService.refresh();
    }

    // ------------------------------------------------- wallhaven provider

    function whSearch(force) {
        // Never gate on isWallhaven here: onProviderChanged runs before it re-evaluates
        // (local->wallhaven bailed with no results) — the handler passes force=true instead.
        if (!force && !root.isWallhaven)
            return;
        root._whSeq++;
        root.whLoading = true;
        setProgress("searching");
        // In-flight run: let it finish and start the newest request from its onExited.
        // Killing it delivered SIGTERM as a failure of the run that replaced it.
        if (whSearchProc.running)
            return;
        startWhSearch();
    }

    function startWhSearch() {
        const w = root.wh;
        const cmd = ["python3", root.wallhavenScript, "--search", "--categories", w.categories, "--purity", w.purity, "--sorting", w.sorting, "--order", w.order, "--page", String(w.page)];
        if (w.q !== "")
            cmd.push("--q", w.q);
        if (w.sorting === "toplist" && w.topRange !== "")
            cmd.push("--top-range", w.topRange);
        if (w.atleast !== "")
            cmd.push("--atleast", w.atleast);
        if (w.ratios !== "")
            cmd.push("--ratios", w.ratios);
        // Random paging repeats without the seed the API returned.
        if (w.sorting === "random" && root.whMeta.seed !== "")
            cmd.push("--seed", root.whMeta.seed);
        if (root.whApiKey !== "")
            cmd.push("--api-key", root.whApiKey);
        whSearchProc._seq = root._whSeq;
        whSearchProc.command = cmd;
        root._whErr = "";
        whSearchProc.running = true;
    }

    Process {
        id: whSearchProc
        property int _seq: 0
        stdout: StdioCollector {
            onStreamFinished: {
                // _seq is set at start only, so a superseded run's delivery is dropped here
                // (the old per-run overwrite before the kill misread it as current).
                if (whSearchProc._seq !== root._whSeq)
                    return;
                root.whLoading = false;
                try {
                    const payload = JSON.parse(text);
                    root.whResults = payload.data || [];
                    const m = payload.meta || {};
                    root.whMeta = {
                        page: m.page ?? root.wh.page,
                        per_page: m.per_page ?? (payload.data || []).length,
                        total: m.total ?? 0,
                        last_page: m.last_page ?? root.wh.page,
                        seed: m.seed ?? ""
                    };
                    root.progressStatus = "idle";
                } catch (e) {
                    root.notifyError("searching wallhaven", e);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (whSearchProc._seq === root._whSeq)
                    root._whErr = text;
            }
        }
        onExited: code => {
            // A superseded run: its result was dropped, so run the request that replaced it.
            if (whSearchProc._seq !== root._whSeq) {
                root.startWhSearch();
                return;
            }
            root.whLoading = false;
            if (code !== 0) {
                let msg = "search failed (exit " + code + ")";
                try {
                    msg = JSON.parse(root._whErr).message || msg;
                } catch (e) {}
                root.notifyError("searching wallhaven", msg);
            }
        }
    }

    // Save + apply: download the full-res file into wallpapersDir (a permanent local category),
    // then reuse applyWallpaper so the badge and delete behave identically.
    function whSaveApply(item, apply) {
        if (!item || whDownloadProc.running)
            return;
        const base = ((item.full !== "" ? item.full : item.id).split("/").pop().split("?")[0]) || (item.id + ".jpg");
        const dest = root.wallpapersDir + "/" + base;
        setProgress("downloading");
        root._pendingWhApply = apply ? "apply" : "";
        root._whDownloadedPath = "";
        const cmd = ["python3", root.wallhavenScript, "--download", item.id, "--dest", dest];
        if (item.full !== "")
            cmd.push("--full-url", item.full);
        if (root.whApiKey !== "")
            cmd.push("--api-key", root.whApiKey);
        whDownloadProc.command = cmd;
        whDownloadProc.running = true;
    }

    Process {
        id: whDownloadProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root._whDownloadedPath = JSON.parse(text).path || "";
                } catch (e) {
                    root._whDownloadedPath = "";
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root._whErr = text;
            }
        }
        onExited: code => {
            const doApply = root._pendingWhApply === "apply";
            const path = root._whDownloadedPath;
            root._pendingWhApply = "";
            if (code === 0 && path !== "") {
                // The file shows up in the Pictures category; the
                // apply path below owns progress from here.
                root.fetchWallpapers();
                if (doApply) {
                    root.applyWallpaper(path);
                } else {
                    Notifications.notify({
                        summary: "Success",
                        body: "Wallpaper saved to Pictures/Wallpapers."
                    });
                    root.setProgress("success");
                }
            } else {
                let msg = "download failed (exit " + code + ")";
                try {
                    msg = JSON.parse(root._whErr).message || msg;
                } catch (e) {}
                root.notifyError("saving wallhaven wallpaper", msg);
            }
        }
    }

    // ----------------------------------------------------------- set/apply

    // set-wallpaper.sh sets one wallpaper on every monitor, regenerates the colours with
    // matugen and records the choice in the state file read above.
    Process {
        id: setProc
        onExited: code => {
            if (code === 0) {
                currentFile.reload();
                root.setProgress("success");
            } else {
                root.notifyError("setting wallpaper", "set-wallpaper.sh failed (exit " + code + ")");
            }
        }
    }

    function applyWallpaper(path) {
        // One at a time: a second apply mid-flight would race the state file.
        if (setProc.running)
            return;
        setProgress("setting");
        setProc.command = [root.dotfilesDir + "/scripts/set-wallpaper.sh", String(path)];
        setProc.running = true;
    }

    function setRandomWallpaper() {
        const list = root.selectedWallpapers;
        if (list.length === 0)
            return;
        applyWallpaper(list[Math.floor(Math.random() * list.length)]);
    }

    // -------------------------------------------------------------- delete

    Process {
        id: deleteProc
        onExited: code => {
            root.fetchWallpapers();
            if (code === 0) {
                Notifications.notify({
                    summary: "Success",
                    body: "Wallpaper deleted successfully!"
                });
                root.setProgress("success");
            } else {
                root.setProgress("error");
            }
        }
    }
    function deleteWallpaper(path) {
        if (deleteProc.running)
            return;
        setProgress("deleting");
        deleteProc.command = ["bash", "-c", `rm -f ${JSON.stringify(path)}`];
        deleteProc.running = true;
    }
    function copyWallpaperPath(path) {
        const p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        const label = "Wallpaper path";
        p.command = ["bash", "-c", "echo -n " + JSON.stringify(String(path)) + " | wl-copy"];
        p.running = true;
        p.exited.connect(function (code) {
            if (code === 0)
                Notifications.notify({
                    summary: "Copied to Clipboard",
                    body: label + " copied successfully!"
                });
            else
                Notifications.notify({
                    summary: "Error",
                    body: "Failed to copy to clipboard"
                });
            p.destroy();
        });
    }

    // --------------------------------------------------------- add wallpaper

    Process {
        id: pickProc
        command: ["zenity", "--file-selection", "--title=Select Wallpaper", "--file-filter=Images (png, jpg, webp, gif, mp4) | *.png *.jpg *.jpeg *.webp *.gif *.mp4"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path.length > 0)
                    root.importWallpaper(path);
                else
                    root.progressStatus = "idle";
            }
        }
        onExited: code => {
            // zenity exits 1 on Cancel — that's not a real error.
            if (code !== 0 && code !== 1)
                root.setProgress("error");
        }
    }
    function pickWallpaper() {
        pickProc.running = true;
    }

    Process {
        id: importProc
        onExited: code => {
            if (code === 0) {
                Notifications.notify({
                    summary: "Success",
                    body: "Wallpaper added successfully!"
                });
                root.fetchWallpapers();
                root.setProgress("success");
            } else {
                root.notifyError("adding wallpaper", "copy step failed");
            }
        }
    }
    function importWallpaper(sourcePath) {
        if (importProc.running)
            return;
        setProgress("adding");
        const targetDir = root.wallpapersDir;
        const basename = sourcePath.split("/").pop();
        const targetPath = targetDir + "/" + basename;

        importProc.command = ["bash", "-c", `mkdir -p ${JSON.stringify(targetDir)} && ` + `cp -- ${JSON.stringify(sourcePath)} ${JSON.stringify(targetPath)}`];
        importProc.running = true;
    }

    // cached file sizes for tooltip (path -> bytes), one stat per path.
    // Path passed as argv (no shell quoting) so names with quotes still work.
    property var fileSizes: ({})
    function getFileSize(path) {
        if (root.fileSizes[path] !== undefined)
            return root.fileSizes[path];
        const p = Qt.createQmlObject('import Quickshell.Io; Process { stdout: StdioCollector {} }', root);
        p.command = ["stat", "-c", "%s", path];
        p.running = true;
        p.stdout.onStreamFinished.connect(function () {
            const sz = parseInt(p.stdout.text.trim()) || 0;
            const fs = root.fileSizes;
            fs[path] = sz;
            root.fileSizes = fs;
            p.destroy();
        });
        return 0;
    }
    function formatBytes(bytes) {
        if (bytes === 0)
            return "N/A";
        const units = ["B", "KB", "MB", "GB"];
        let i = 0;
        let b = bytes;
        while (b >= 1024 && i < units.length - 1) {
            b /= 1024;
            i++;
        }
        return b.toFixed(i === 0 ? 0 : 1) + " " + units[i];
    }

    // ------------------------------------------------------------------ UI

    Rectangle {
        id: wallpaperSwitcher
        anchors.fill: parent
        color: "transparent"
        radius: Theme.radius

        ColumnLayout {
            id: mainCol
            anchors.fill: parent
            // No outer margin: Theme.islandPad is the only inset between pill edge and content —
            // adding one here stacks a second (this body used to add 12).
            spacing: Theme.spacing

            // action bar — wrapped so radius / bg / border apply as one pill
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: actionBar.implicitWidth + 16
                implicitHeight: actionBar.implicitHeight + 10
                radius: Theme.radius
                color: Theme.surface

                clip: true

                RowLayout {
                    id: actionBar
                    anchors.centerIn: parent
                    spacing: Theme.spacing

                    // Provider switch: local folders vs. wallhaven.cc API.
                    AppSegmentedControl {
                        model: root.providerTypes
                        currentIndex: root.providerTypes.indexOf(root.provider)
                        cellHPadding: 8
                        cellVPadding: 4
                        onActivated: (i, v) => Settings.updateSetting("wallpaperSwitcher.provider", v)
                    }

                    AppComboBox {
                        id: categoryCombo
                        objectName: "categoryCombo"
                        visible: !root.isWallhaven
                        model: root.categories
                        Layout.preferredHeight: 26
                        currentIndex: root.categories.indexOf(root.selectedCategory)
                        onActivated: i => Settings.updateSetting("wallpaperSwitcher.category", root.categories[i])
                    }

                    AppButton {
                        tooltipText: "Set a random wallpaper from this view"
                        text: "Random"
                        visible: !root.isWallhaven
                        Layout.preferredHeight: 26
                        onClicked: root.setRandomWallpaper()
                    }
                    AppButton {
                        tooltipText: "Pick a wallpaper image to add"
                        text: "Add…"
                        Layout.preferredHeight: 26
                        onClicked: root.pickWallpaper()
                    }

                    // Shared masonry view (both providers, persisted).
                    AppButton {
                        text: "‹"
                        tooltipText: "Fewer masonry rows"
                        enabled: Settings.wallpaperMasonryRows > 1
                        Layout.preferredHeight: 26
                        onClicked: root.setMasonryRows(Settings.wallpaperMasonryRows - 1)
                    }
                    Text {
                        text: Settings.wallpaperMasonryRows + (Settings.wallpaperMasonryRows === 1 ? " row" : " rows")
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                    AppButton {
                        text: "›"
                        tooltipText: "More masonry rows"
                        enabled: Settings.wallpaperMasonryRows < 4
                        Layout.preferredHeight: 26
                        onClicked: root.setMasonryRows(Settings.wallpaperMasonryRows + 1)
                    }
                    AppSlider {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 26
                        from: 80
                        to: 200
                        stepSize: 10
                        value: Settings.wallpaperTileSize
                        onValueChanged: {
                            // Same binding guard as the booru sliders: the settings write re-evaluates
                            // value to the same number, which must not write back in a loop.
                            const v = Math.round(value);
                            if (v === Settings.wallpaperTileSize)
                                return;
                            Settings.updateSetting("wallpaperSwitcher.tileSize", v);
                        }
                    }
                    Text {
                        text: Settings.wallpaperTileSize + "px"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }

                    Text {
                        // Phased progress text (replaces the spinner): fixed
                        // width so phase changes don't jitter the action bar.
                        width: 70
                        elide: Text.ElideRight
                        text: root.progressText
                        color: root.progressColor
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }

            // wallhaven provider: dynamic filter form. Each control writes one wallpaperWallhaven
            // field via setWh (debounced search); the form renders the provider's declared params.
            Rectangle {
                visible: root.isWallhaven
                Layout.fillWidth: true
                implicitHeight: whFilterCol.implicitHeight + 10
                radius: Theme.radius
                color: Theme.surface
                clip: true

                ColumnLayout {
                    id: whFilterCol
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: Theme.spacing

                    // filters: one wrapping row (query, sort, categories,
                    // purity, size) so every provider filter lives together.
                    Flow {
                        Layout.fillWidth: true
                        spacing: Theme.spacing
                        AppTextField {
                            id: whQuery
                            width: 180
                            placeholderText: "Search wallhaven.cc (tags, e.g. mountains lake)…"
                            text: root.wh.q
                            onTextChanged: {
                                if (text !== root.wh.q)
                                    root.setWh("q", text);
                            }
                        }
                        AppComboBox {
                            model: root.whSortingItems
                            implicitHeight: 26
                            currentIndex: Math.max(0, root.whSortingItems.indexOf(root.wh.sorting))
                            onActivated: i => root.setWh("sorting", root.whSortingItems[i])
                        }
                        AppComboBox {
                            model: root.whOrderItems
                            implicitHeight: 26
                            currentIndex: Math.max(0, root.whOrderItems.indexOf(root.wh.order))
                            onActivated: i => root.setWh("order", root.whOrderItems[i])
                        }
                        AppComboBox {
                            visible: root.wh.sorting === "toplist"
                            model: root.whTopRangeItems
                            implicitHeight: 26
                            currentIndex: Math.max(0, root.whTopRangeItems.indexOf(root.wh.topRange))
                            onActivated: i => root.setWh("topRange", root.whTopRangeItems[i])
                        }
                        AppFilterChips {
                            label: "Categories:"
                            model: root.whCategoryNames
                            checkedValues: {
                                const out = [];
                                for (let i = 0; i < root.whCategoryNames.length; i++) {
                                    if (root.wh.categories.charAt(i) === "1")
                                        out.push(root.whCategoryNames[i]);
                                }
                                return out;
                            }
                            allowEmpty: false
                            onToggled: (i, v, checked) => {
                                const bits = root.wh.categories.split("");
                                bits[i] = checked ? "1" : "0";
                                root.setWh("categories", bits.join(""));
                            }
                            onEmptyRejected: Notifications.notify({
                                summary: "Wallhaven",
                                body: "At least one category must stay on."
                            })
                        }
                        Text {
                            text: "Purity:"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            height: 26
                            verticalAlignment: Text.AlignVCenter
                        }
                        Repeater {
                            model: [
                                {
                                    label: "SFW",
                                    value: "100"
                                },
                                {
                                    label: "Sketchy",
                                    value: "110"
                                },
                                {
                                    label: "NSFW",
                                    value: "111"
                                }
                            ]
                            delegate: AppButton {
                                required property var modelData
                                readonly property bool on: root.wh.purity === modelData.value
                                readonly property bool needsKey: modelData.value === "111"
                                enabled: !needsKey || root.whApiKey !== ""
                                text: modelData.label
                                height: 24
                                pixelSize: Theme.fontSize - 2
                                idleBg: on ? Theme.surfaceActive : Theme.bg
                                idleFg: on ? Theme.accent : Theme.fg
                                hoverFg: on ? Theme.accent : Theme.fg
                                outlined: true
                                outlineColor: on ? Theme.accent : Theme.border
                                tooltipText: (needsKey && root.whApiKey === "") ? "Needs a Wallhaven API key (Settings → API Keys)" : ""
                                onClicked: root.setWh("purity", modelData.value)
                            }
                        }
                        AppComboBox {
                            model: root.whAtleastItems
                            implicitHeight: 26
                            currentIndex: Math.max(0, root.whAtleastItems.indexOf(root.whMapped(root.wh.atleast, root.whAtleastItems)))
                            onActivated: i => root.setWh("atleast", root.whUnmap(root.whAtleastItems[i], root.whAtleastItems))
                        }
                        AppComboBox {
                            model: root.whRatioItems
                            implicitHeight: 26
                            currentIndex: Math.max(0, root.whRatioItems.indexOf(root.whMapped(root.wh.ratios, root.whRatioItems)))
                            onActivated: i => root.setWh("ratios", root.whUnmap(root.whRatioItems[i], root.whRatioItems))
                        }
                    }

                    // result count + page nav
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            text: root.whLoading ? "Searching…" : root.whMeta.total + " results • page " + root.whMeta.page + "/" + root.whMeta.last_page
                        }
                        AppButton {
                            text: "‹"
                            tooltipText: "Previous Wallhaven page"
                            enabled: root.wh.page > 1 && !root.whLoading
                            Layout.preferredHeight: 26
                            onClicked: root.setWh("page", Math.max(1, root.wh.page - 1), true)
                        }
                        AppButton {
                            text: "›"
                            tooltipText: "Next Wallhaven page"
                            enabled: root.wh.page < root.whMeta.last_page && !root.whLoading
                            Layout.preferredHeight: 26
                            onClicked: root.setWh("page", root.wh.page + 1, true)
                        }
                    }
                }
            }

            // all wallpapers in the selected category — horizontal strip
            SmoothFlickable {
                id: wallScroll
                objectName: "wallStrip"
                visible: !root.isWallhaven
                Layout.fillWidth: true
                Layout.preferredHeight: root.resultsH
                flickableDirection: Flickable.HorizontalFlick
                contentWidth: localMasonry.contentWidth
                contentHeight: height
                ScrollBar.horizontal: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                AppMasonryRow {
                    id: localMasonry
                    width: wallScroll.width
                    height: implicitHeight
                    rows: Settings.wallpaperMasonryRows
                    spacing: Theme.spacing
                    rowHeight: Settings.wallpaperTileSize
                    // Preserve the (alphabetically sorted) file order left-to-right instead of
                    // shortest-row bin-packing, which shuffled tiles as aspects refined.
                    balanceRows: false
                    model: root.selectedWallpapers
                    aspectRatio: function (path) {
                        return root.localAspectOf(path);
                    }
                    // Lazy window: instantiate only tiles near the viewport (fast open on 100+
                    // folders, decoders freed when scrolled away).
                    viewLeft: wallScroll.contentX - 700
                    viewRight: wallScroll.contentX + wallScroll.width + 700
                    buffer: 700
                    placeholder: Rectangle {
                        color: Theme.surface
                        radius: Theme.radius
                    }
                    delegate: Rectangle {
                        id: tile
                        // Plain (not required) modelData — the masonry pushes
                        // it via Loader onLoaded (same contract as AppMasonry).
                        property var modelData
                        // Masonry widths are always aspect-derived (a hover-expand would fight the
                        // layout); each thumb reports its decoded ratio back, refining the width.
                        width: localMasonry.widthFor(modelData)
                        height: localMasonry.rowHeight
                        // Fades in once the preview settles (image decoded or Error, video ready);
                        // modelData arrives via Loader push after creation, so every access is guarded.
                        readonly property string tileThumb: root.thumbFor(tile.modelData)
                        readonly property bool thumbSettled: (tile.modelData !== undefined && root.isVideoFile(tile.modelData)) ? (tile.previewing ? tileVideo.ready : (tile.tileThumb === "" || tileImg.status === Image.Ready || tileImg.status === Image.Error)) : (tileImg.status === Image.Ready || tileImg.status === Image.Error)
                        // Current-wallpaper badge (top-right), shared by the still preview and
                        // the live video (only one is visible).
                        readonly property var badgeIds: root.isCurrentWallpaper(tile.modelData) ? ["current"] : []
                        opacity: tile.thumbSettled ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }
                        // Stagger timers and hover-expand are gone: widths
                        // are masonry-owned (see delegate header).
                        readonly property string fileName: tile.modelData === undefined ? "" : String(tile.modelData).split("/").pop()
                        // Two-step delete confirm: first click arms (trash ->
                        // check + red), second click deletes. Reset on leave.
                        property bool deleteArmed: false
                        Timer {
                            id: disarmTimer
                            interval: 3000
                            onTriggered: tile.deleteArmed = false
                        }
                        radius: Theme.radius
                        color: tileMa.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.width: tileMa.containsMouse ? 2 : 0
                        border.color: Theme.muted

                        AppImage {
                            id: tileImg
                            anchors.fill: parent
                            // Zero inset so tiles read edge-to-edge like the booru masonry; the hover
                            // border overlaps the edge by design. Images decode the original file.
                            source: (tile.modelData === undefined) ? "" : (root.isVideoFile(tile.modelData) ? (tile.tileThumb !== "" ? "file://" + tile.tileThumb : "") : "file://" + tile.modelData)
                            // Decode at a stable width: sourceWidth following the aspect-derived width
                            // reloaded on every refine (flicker); the fixed rowHeight sizes it instead.
                            sourceWidth: Math.max(1, Math.round(Settings.wallpaperTileSize * 2))
                            badges: tile.badgeIds
                            animated: tileMa.containsMouse && tile.modelData !== undefined && root.isGifFile(tile.modelData)
                            onStatusChanged: {
                                if (tileImg.status === Image.Ready && tileImg.implicitImageWidth > 0 && tileImg.implicitImageHeight > 0)
                                    root.noteLocalAspect(tile.modelData, tileImg.implicitImageWidth / tileImg.implicitImageHeight);
                            }
                        }
                        // Live video preview: shared AppVideo, muted + looping, ON HOVER ONLY — a
                        // video folder opens ~25 tiles and autoplaying them all froze the panel.
                        readonly property bool previewing: tile.modelData !== undefined && root.isVideoFile(tile.modelData) && tileMa.containsMouse
                        AppVideo {
                            id: tileVideo
                            anchors.fill: parent
                            // Zero inset: parity with the still thumb (and thus
                            // the booru masonry gaps) — no ring on hover-expand.
                            visible: tile.previewing
                            source: tile.previewing ? tile.modelData : ""
                            active: tile.previewing
                            muted: true
                            fillMode: VideoOutput.PreserveAspectCrop
                            badges: tile.badgeIds
                            onReadyChanged: {
                                if (tileVideo.ready && tileVideo.videoRatio > 0)
                                    root.noteLocalAspect(tile.modelData, tileVideo.videoRatio);
                            }
                            onErrorOccurred: message => {
                                console.warn("[WallpaperSwitcher] video preview failed for " + tile.modelData + ": " + message);
                            }
                        }
                        Column {
                            // Idle fallback for videos: no thumb mapped yet (generator running) or
                            // the thumb failed — same icon look; hover swaps in the live preview.
                            visible: tile.modelData !== undefined && root.isVideoFile(tile.modelData) && !tile.previewing && (tile.tileThumb === "" || tileImg.status === Image.Error)
                            anchors.centerIn: parent
                            spacing: Theme.spacing
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Icons.video
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(2)
                                color: Theme.fgDim
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.fileName
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                color: Theme.fgDim
                                elide: Text.ElideMiddle
                                width: Math.max(0, tile.width - 16)
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Hidden while the strip moves: a visible tooltip window sits under the cursor
                        // and swallows wheel events, killing the momentum glide.
                        AppTooltip {
                            visible: tileMa.containsMouse && !wallScroll.moving
                            delay: 400
                            text: `Click to set as wallpaper.\nRight-click to delete.\n${(tile.modelData !== undefined && root.isAnimatedPreviewFile(tile.modelData)) ? "Hover to preview.\n" : ""}${tile.fileName}\nSize: ${root.formatBytes(root.getFileSize(tile.modelData ?? ""))}`
                        }

                        MouseArea {
                            id: tileMa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            // Tiles cover the strip: let wheel fall through to the strip's
                            // SmoothWheelHandler so the horizontal glide receives it.
                            onWheel: wheel => wheel.accepted = false
                            onContainsMouseChanged: {
                                if (!containsMouse && !copyMa.containsMouse && !delMa.containsMouse)
                                    tile.deleteArmed = false;
                            }
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton)
                                    root.deleteWallpaper(tile.modelData);
                                else
                                    root.applyWallpaper(tile.modelData);
                            }
                        }

                        // Local-only action overlay (top-left, badge-style): copy path + two-step
                        // delete; badges already occupy top-right. Above tileMa so clicks land.
                        Row {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 4
                            spacing: Theme.spacing
                            readonly property bool hovered: tile.modelData !== undefined && (tileMa.containsMouse || copyMa.containsMouse || delMa.containsMouse)
                            opacity: hovered ? 1 : 0
                            visible: hovered || opacity > 0
                            Behavior on opacity {
                                Anim {
                                    type: Anim.FastEffects
                                }
                            }
                            Rectangle {
                                width: 24
                                height: 18
                                radius: Theme.radius
                                color: Theme.muted
                                opacity: Theme.opacity.soft
                                Text {
                                    anchors.centerIn: parent
                                    text: Icons.copy
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeBadge
                                    color: Theme.onMediaInk
                                }
                                MouseArea {
                                    id: copyMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: Qt.PointingHandCursor
                                    onWheel: wheel => wheel.accepted = false
                                    onClicked: mouse => {
                                        mouse.accepted = true;
                                        root.copyWallpaperPath(tile.modelData);
                                    }
                                }
                            }
                            Rectangle {
                                width: 24
                                height: 18
                                radius: Theme.radius
                                color: tile.deleteArmed ? Theme.color1 : Theme.muted
                                opacity: tile.deleteArmed ? 1.0 : 0.9
                                Text {
                                    anchors.centerIn: parent
                                    text: tile.deleteArmed ? Icons.check : Icons.trash
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeBadge
                                    color: Theme.onMediaInk
                                }
                                MouseArea {
                                    id: delMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: Qt.PointingHandCursor
                                    onWheel: wheel => wheel.accepted = false
                                    onContainsMouseChanged: {
                                        if (!containsMouse && !tileMa.containsMouse)
                                            tile.deleteArmed = false;
                                    }
                                    onClicked: mouse => {
                                        mouse.accepted = true;
                                        if (!tile.deleteArmed) {
                                            tile.deleteArmed = true;
                                            disarmTimer.restart();
                                        } else {
                                            disarmTimer.stop();
                                            tile.deleteArmed = false;
                                            root.deleteWallpaper(tile.modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // wallhaven results — remote thumbs with the same tile chrome: click downloads the
            // full-res file into Pictures/Wallpapers and applies it, right-click saves only.
            SmoothFlickable {
                id: whScroll
                visible: root.isWallhaven
                Layout.fillWidth: true
                Layout.preferredHeight: root.resultsH
                flickableDirection: Flickable.HorizontalFlick
                contentWidth: whMasonry.contentWidth
                contentHeight: height
                ScrollBar.horizontal: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    
                }

                AppMasonryRow {
                    id: whMasonry
                    width: whScroll.width
                    height: implicitHeight
                    rows: Settings.wallpaperMasonryRows
                    spacing: Theme.spacing
                    rowHeight: Settings.wallpaperTileSize
                    model: root.whResults
                    aspectRatio: function (item) {
                        return root.whAspect(item);
                    }
                    viewLeft: whScroll.contentX - 700
                    viewRight: whScroll.contentX + whScroll.width + 700
                    buffer: 700
                    placeholder: Rectangle {
                        color: Theme.surface
                        radius: Theme.radius
                    }
                    delegate: Rectangle {
                        id: whTile
                        // Plain (not required) modelData — pushed by the
                        // masonry via Loader (same contract as AppMasonry).
                        property var modelData
                        width: whMasonry.widthFor(modelData)
                        height: whMasonry.rowHeight
                        // Fades in once the remote thumb decodes (Error
                        // counts as settled so a dead URL can't hide a tile).
                        readonly property bool thumbSettled: whImg.status === Image.Ready || whImg.status === Image.Error
                        readonly property string res: whTile.modelData === undefined ? "" : (whTile.modelData.resolution || "")
                        opacity: whTile.thumbSettled ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }
                        radius: Theme.radius
                        color: whTileMa.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.width: whTileMa.containsMouse ? 2 : 0
                        border.color: Theme.muted

                        AppImage {
                            id: whImg
                            anchors.fill: parent
                            // Zero inset: parity with the local-masonry thumb
                            // (tiles read edge-to-edge, booru masonry gaps).
                            source: whTile.modelData === undefined ? "" : whTile.modelData.preview
                            sourceWidth: Math.max(1, Math.round(whTile.width))
                            badges: [whTile.res !== "" ? whTile.res : (whTile.modelData === undefined ? "" : whTile.modelData.purity)]
                        }

                        // Hidden while the strip moves (same wheel-glide
                        // reason as the local tiles above).
                        AppTooltip {
                            visible: whTileMa.containsMouse && !whScroll.moving
                            delay: 400
                            text: whTile.modelData === undefined ? "" : `${whTile.modelData.id} • ${whTile.res} • ${whTile.modelData.purity}/${whTile.modelData.category}\nClick: download + apply.\nRight-click: save only.`
                        }

                        MouseArea {
                            id: whTileMa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onWheel: wheel => wheel.accepted = false
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton)
                                    root.whSaveApply(whTile.modelData, false);
                                else
                                    root.whSaveApply(whTile.modelData, true);
                            }
                        }
                    }
                }

                // Empty state (contentWidth is 0, so this never scrolls away).
                Text {
                    visible: root.whResults.length === 0 && !root.whLoading
                    text: "No results — try a different query or filter."
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    x: 12
                    y: (whScroll.height - height) / 2
                }
            }
        }
    }
}
