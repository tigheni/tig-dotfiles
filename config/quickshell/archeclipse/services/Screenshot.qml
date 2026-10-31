pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Owns every flameshot spawn because destroying a Process kills its child
// (the screenshot island folds away mid-capture), as ScreenRecorder does.
// flameshot matches the Print bind in config/hypr/configs/binds.conf.
QtObject {
    id: root

    property Process _shotProc: Process {
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: code => {
            const detail = ((_shotProc.stderr.text ?? "") + " " + (_shotProc.stdout.text ?? "")).trim();
            // A cancelled capture exits non-zero with no output — a
            // deliberate no-op.
            if (code === 0 || detail === "")
                return;
            console.warn("[Screenshot] shot exited (" + code + "): " + detail);
            Notifications.send("Screenshot Error", detail);
        }
    }

    // "area" opens the flameshot selection UI, anything else copies the screen under
    // the pointer to the clipboard. One shot at a time: reassigning `command` mid-run swaps the invocation.
    function capture(mode, monitorName) {
        if (root._shotProc.running)
            return false;
        root._shotProc.command = mode === "area" ? ["flameshot", "gui"] : ["flameshot", "screen", "-c"];
        root._shotProc.running = true;
        return true;
    }
}
