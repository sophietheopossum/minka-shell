import QtQuick
import Quickshell.Services.UPower
import "../../services"

// Battery as a tray-style icon applet, from UPower's aggregate display
// device. Hidden entirely on desktops.
// The percent (sans % sign) renders inside the battery body
// over deliberately dim fills — the number is the
// primary readout, the fill a secondary cue. Red when low; purple lightning
// beside the icon while charging. Click opens the battery menu.
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
    width: chargeBolt.visible ? 26 + 2 + chargeBolt.implicitWidth : 26
    height: 18

    Rectangle {
        id: body

        anchors.verticalCenter: parent.verticalCenter
        x: 0
        width: 24
        height: 13
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
            color: root.low ? Theme.redDim : root.charging ? Theme.purpleDim : Theme.line
        }

        Text {
            anchors.centerIn: parent
            text: root.percent
            font.family: Theme.monoFamily
            font.pixelSize: 9
            font.bold: true
            color: root.low ? Theme.red : Theme.text
        }
    }

    // Terminal nub.
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: body.right
        width: 2
        height: 6
        color: root.chromeColor
    }

    Text {
        id: chargeBolt

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: body.right
        anchors.leftMargin: 4
        visible: root.charging
        text: "⚡"
        font.pixelSize: 9
        color: Theme.purple
    }

    MouseArea {
        id: batteryArea

        anchors.fill: parent
        hoverEnabled: true
        onClicked: MenuState.toggle("battery", root.monitorName)
    }
}