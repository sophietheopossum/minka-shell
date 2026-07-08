import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "../../services"

// StatusNotifier tray. Left click activates (or opens the menu for
// menu-only items); right click opens the item's DBus menu in our own
// themed popup (TrayMenu); middle click secondary-activates.
Row {
    id: root

    spacing: 6

    TrayMenu {
        id: trayMenu
    }

    function openMenuFor(item, anchorItem) {
        // Same handle already open -> treat the click as a toggle.
        if (trayMenu.visible && trayMenu.menuHandle === item.menu) {
            trayMenu.dismiss();
            return;
        }
        const window = root.QsWindow.window;
        if (!window || !item.menu)
            return;
        // Position under the icon, in window coordinates; clamp so the
        // popup never overflows the right screen edge.
        const pos = anchorItem.mapToItem(null, 0, anchorItem.height + 7);
        const x = Math.min(pos.x, window.width - trayMenu.implicitWidth - 8);
        trayMenu.openAt(window, x, pos.y, item.menu);
    }

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
                            root.openMenuFor(item, trayItem);
                    } else {
                        item.activate();
                    }
                }
            }
        }
    }
}
