import QtQuick
import "../../services"

// Minimize / maximize-restore controls for the focused window (same lookup
// as FocusedTitle).
// These replaced the titlebar buttons, so they mirror that
// styling exactly: 16px circles, constant frosted fill, a tinted border that
// fades out on hover while the icon fades in.
Row {
    id: root

    required property string monitorName

    readonly property var focusedWindow: ShojiIpc.focusedWindowFor(monitorName)

    visible: focusedWindow !== null
    spacing: 8

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: "#20FFFFFF"
        border.width: 1
        border.color: minimizeArea.containsMouse ? "transparent" : "#30F8FF75"

        Image {
            anchors.fill: parent
            source: "../../assets/minus.svg"
            sourceSize: Qt.size(16, 16)
            visible: minimizeArea.containsMouse
        }

        MouseArea {
            id: minimizeArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (!root.focusedWindow)
                    return;
                // A minimized window keeps focus, so the same button restores
                // it: windows.activate unminimizes and refocuses.
                if (root.focusedWindow.minimized)
                    ShojiIpc.activateWindow(root.focusedWindow.id);
                else
                    ShojiIpc.minimizeWindow(root.focusedWindow.id);
            }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: "#20FFFFFF"
        border.width: 1
        border.color: maximizeArea.containsMouse ? "transparent" : "#3000BFFF"

        Image {
            anchors.fill: parent
            source: root.focusedWindow && root.focusedWindow.maximized
                ? "../../assets/minimize-2.svg"
                : "../../assets/maximize-2.svg"
            sourceSize: Qt.size(16, 16)
            visible: maximizeArea.containsMouse
        }

        MouseArea {
            id: maximizeArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (root.focusedWindow)
                    ShojiIpc.maximizeWindow(
                        root.focusedWindow.id,
                        !root.focusedWindow.maximized);
            }
        }
    }
}