import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "../../services"

// StatusNotifier tray. Left click activates (or opens the menu for
// menu-only items); right click opens the item's DBus menu as a native
// popup anchored under the icon; middle click secondary-activates.
Row {
    id: root

    spacing: 6

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem

            required property var modelData

            width: 18
            height: 18
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                source: trayItem.modelData.icon
                sourceSize.width: 18
                sourceSize.height: 18
                fillMode: Image.PreserveAspectFit
                opacity: trayArea.containsMouse ? 1.0 : 0.85
            }

            // Native menu popup anchored to this icon, opening downward
            // from under the bar. (The previous display() call referenced
            // the QsWindow attached property from plain JS, which is
            // invalid and errored on menu-carrying items like CMST.)
            QsMenuAnchor {
                id: menuAnchor

                menu: trayItem.modelData.menu
                anchor.item: trayItem
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
            }

            MouseArea {
                id: trayArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    const item = trayItem.modelData;
                    if (mouse.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu)
                            menuAnchor.open();
                    } else {
                        item.activate();
                    }
                }
            }
        }
    }
}
