import QtQuick
import "../../services"

// Minimize / maximize-restore controls for the focused window (same lookup
// as FocusedTitle). Complements the always-centred unmaximize: even with a
// titlebar somehow out of reach, the window stays controllable from the bar.
Row {
    id: root

    required property string monitorName

    readonly property var focusedWindow: ShojiIpc.focusedWindowFor(monitorName)

    visible: focusedWindow !== null
    spacing: 4

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 22
        radius: 5
        color: minimizeArea.containsMouse ? Theme.surfaceRaised : "transparent"

        Text {
            anchors.centerIn: parent
            text: "–"
            font.family: Theme.monoFamily
            font.pixelSize: Theme.fontSize + 1
            color: minimizeArea.containsMouse ? Theme.red : Theme.textMuted
        }

        MouseArea {
            id: minimizeArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (root.focusedWindow)
                    ShojiIpc.minimizeWindow(root.focusedWindow.id);
            }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 22
        radius: 5
        color: maximizeArea.containsMouse ? Theme.surfaceRaised : "transparent"

        Text {
            anchors.centerIn: parent
            text: root.focusedWindow && root.focusedWindow.maximized ? "❐" : "□"
            font.family: Theme.monoFamily
            font.pixelSize: Theme.fontSize + 1
            color: maximizeArea.containsMouse ? Theme.red : Theme.textMuted
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