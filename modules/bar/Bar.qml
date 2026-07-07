import Quickshell
import QtQuick
import "../../services"

// Top panel, one per output. Instantiated by Variants in shell.qml, which
// injects the screen as modelData. Duo mode hides it on the main display —
// unmapping the surface also releases the exclusive zone.
PanelWindow {
    id: root

    required property var modelData

    screen: modelData
    visible: ShellLayout.showBarOn(modelData)

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Theme.barBg

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.line
        }

        Workspaces {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            monitorName: root.modelData.name
        }

        Clock {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        // IPC health: red until the first workspace view arrives on the
        // current connection. Tray, battery, status menus join here in M2.
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 7
            height: 7
            radius: 3.5
            color: ShojiIpc.ready ? Theme.redDim : Theme.red

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
    }
}
