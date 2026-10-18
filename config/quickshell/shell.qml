import Quickshell
import Quickshell.Io

ShellRoot {
    Dashboard {
        id: dashboard
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            dashboard.open = !dashboard.open;
        }

        function open(): void {
            dashboard.open = true;
        }

        function close(): void {
            dashboard.open = false;
        }
    }
}
