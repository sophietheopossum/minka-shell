import QtQuick
import "../../services"

// Title of this monitor's focused window, from the workspaces view — the
// compositor's focused flag is only set on the monitor that owns focus, so
// each bar naturally shows only its own.
Text {
    id: root

    required property string monitorName

    readonly property var focusedWindow: {
        const monitor = ShojiIpc.monitorView(monitorName);
        if (!monitor)
            return null;
        for (const workspace of monitor.workspaces)
            for (const win of workspace.windows)
                if (win.focused)
                    return win;
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
