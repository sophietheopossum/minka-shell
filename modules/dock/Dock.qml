import Quickshell
import QtQuick
import "../../services"

// Auto-revealing dock, one per output. Reveal is driven entirely by the
// compositor's dock.proximity broadcast (10px show / 120px hide hysteresis
// lives in the ShojiWM config) — no trigger surface on our side, so hidden
// state costs nothing and steals no clicks. Items are the monitor's running
// windows; pinned apps come later with the M4 config file.
PanelWindow {
    id: root

    required property var modelData

    readonly property bool revealed: ShojiIpc.dockProximity[modelData.name] === true
    readonly property var monitor: ShojiIpc.monitorView(modelData.name)
    readonly property var windows: {
        if (!monitor)
            return [];
        const all = [];
        for (const ws of monitor.workspaces)
            for (const win of ws.windows)
                all.push(win);
        return all;
    }

    screen: modelData
    visible: revealed && windows.length > 0
    anchors.bottom: true
    implicitWidth: dockBody.width + 24
    implicitHeight: 62
    exclusiveZone: 0
    color: "transparent"

    Rectangle {
        id: dockBody

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.revealed ? 8 : -height
        width: iconRow.width + 20
        height: 48
        radius: 10
        color: Theme.barBg
        border.width: 1
        border.color: Theme.line

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: iconRow

            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: root.windows

                delegate: Item {
                    id: dockItem

                    required property var modelData

                    readonly property var entry: modelData.appId
                        ? DesktopEntries.heuristicLookup(modelData.appId)
                        : null

                    width: 36
                    height: 40

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        width: 32
                        height: 32
                        sourceSize.width: 32
                        sourceSize.height: 32
                        fillMode: Image.PreserveAspectFit
                        source: dockItem.entry && dockItem.entry.icon
                            ? Quickshell.iconPath(dockItem.entry.icon, "application-x-executable")
                            : Quickshell.iconPath("application-x-executable")
                        scale: itemArea.containsMouse ? 1.12 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 100 }
                        }
                    }

                    // Focus indicator, Eternal-Darkness red.
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: dockItem.modelData.focused ? 14 : 4
                        height: 3
                        radius: 1.5
                        color: dockItem.modelData.focused ? Theme.red : Theme.textFaint

                        Behavior on width {
                            NumberAnimation { duration: 120 }
                        }
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: ShojiIpc.activateWindow(dockItem.modelData.id)
                    }
                }
            }
        }
    }
}
