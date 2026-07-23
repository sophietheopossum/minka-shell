import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"

// Transparent screen-wide click catcher, mapped on every output while a bar
// dropdown (calendar/status/battery) is open: a click anywhere outside the
// menu closes it. Sits on the top layer; the dropdowns themselves are on the
// overlay layer so they deterministically stack above this. The start menu
// is excluded — it is fullscreen and dismisses itself.
PanelWindow {
    id: root

    required property var modelData

    screen: modelData
    visible: MenuState.dropdownOpen
    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0
    color: "transparent"

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: MenuState.closeAll()
    }
}