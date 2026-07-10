import QtQuick
import "../../services"

// Title of the focused window, from the workspaces view — the compositor's
// focused flag is only set on the monitor that owns focus.
// general mode: each bar naturally shows only its own.
// Duo mode: bar on the ScreenPad speaks for every monitor, so it scans the whole view.
Text {
    id: root

    required property string monitorName

    readonly property var focusedWindow: {
        const monitors = ShellLayout.duoMode
            ? (ShojiIpc.view ? ShojiIpc.view.monitors : [])
            : [ShojiIpc.monitorView(monitorName)];
        for (const monitor of monitors) {
            if (!monitor)
                continue;
            for (const workspace of monitor.workspaces)
                for (const win of workspace.windows)
                    if (win.focused)
                        return win;
        }
        return null;
    }

    visible: focusedWindow !== null
    text: focusedWindow ? focusedWindow.title : ""
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize - 1
    color: Theme.textMuted
    elide: Text.ElideRight
    width: Math.min(implicitWidth, 320)
}
