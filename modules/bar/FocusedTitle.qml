import QtQuick
import Quickshell
import "../../services"

// Icon + title
// of the focused window, from the workspaces view. The duo-aware
// focused-window resolution lives in ShojiIpc.focusedWindowFor, shared with
// the bar's window controls.
Row {
    id: root

    required property string monitorName

    readonly property var focusedWindow: ShojiIpc.focusedWindowFor(monitorName)
    readonly property var entry: focusedWindow && focusedWindow.appId
        ? DesktopEntries.heuristicLookup(focusedWindow.appId)
        : null

    visible: focusedWindow !== null
    spacing: 7

    Image {
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        sourceSize.width: 16
        sourceSize.height: 16
        fillMode: Image.PreserveAspectFit
        source: root.entry && root.entry.icon
            ? Quickshell.iconPath(root.entry.icon, "application-x-executable")
            : Quickshell.iconPath("application-x-executable")
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.focusedWindow ? root.focusedWindow.title : ""
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        color: Theme.textMuted
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 320)
    }
}