import QtQuick
import Quickshell.Services.UPower
import "../../services"

// Battery as a tray-style icon applet, from UPower's aggregate display
// device. Hidden entirely on desktops. Red below 20% while discharging;
// purple lightning overlay while charging. Percent/time details live in
// the status menu, which opens on click.
Item {
    id: root

    property string monitorName: ""

    readonly property var device: UPower.displayDevice
    readonly property bool present: device !== null && device.isLaptopBattery
    readonly property bool charging: present && device.state === UPowerDeviceState.Charging
    // UPowerDevice.percentage is a 0-1 fraction (confirmed on hardware:
    // rendering it raw showed "1%" at full charge).
    readonly property int percent: present ? Math.round(device.percentage * 100) : 0
    readonly property bool low: present && !charging && percent <= 20

    readonly property color chromeColor: low ? Theme.red
        : batteryArea.containsMouse ? Theme.text
        : Theme.textFaint

    visible: present
    width: 18
    height: 18

    Rectangle {
        id: body

        anchors.verticalCenter: parent.verticalCenter
        x: 0
        width: 15
        height: 9
        radius: 2
        color: "transparent"
        border.width: 1
        border.color: root.chromeColor

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 2
            width: Math.max(1, (parent.width - 4) * root.percent / 100)
            height: parent.height - 4
            radius: 1
            color: root.low ? Theme.red : root.charging ? Theme.purple : Theme.textMuted
        }
    }

    // Terminal nub.
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: body.right
        width: 2
        height: 5
        color: root.chromeColor
    }

    Text {
        anchors.centerIn: body
        visible: root.charging
        text: "⚡"
        font.pixelSize: 9
        color: Theme.purple
        style: Text.Outline
        styleColor: Theme.ground
    }

    MouseArea {
        id: batteryArea

        anchors.fill: parent
        hoverEnabled: true
        onClicked: MenuState.toggle("status", root.monitorName)
    }
}