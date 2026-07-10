import QtQuick
import "../../services"

// Title of the focused window, from the workspaces view. The duo-aware
// focused-window resolution lives in ShojiIpc.focusedWindowFor, shared with
// the bar's window controls.
Text {
    id: root

    required property string monitorName

    readonly property var focusedWindow: ShojiIpc.focusedWindowFor(monitorName)

    visible: focusedWindow !== null
    text: focusedWindow ? focusedWindow.title : ""
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize - 1
    color: Theme.textMuted
    elide: Text.ElideRight
    width: Math.min(implicitWidth, 320)
}
