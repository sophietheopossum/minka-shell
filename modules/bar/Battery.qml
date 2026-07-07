import QtQuick
import Quickshell.Services.UPower
import "../../services"

// Battery readout from UPower's aggregate display device. Hidden entirely on
// desktops. Red below 20% while discharging; purple lightning while charging.
Row {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device !== null && device.isLaptopBattery
    readonly property bool charging: present && device.state === UPowerDeviceState.Charging
    // UPowerDevice.percentage is 0-100 (energy / energyCapacity).
    readonly property int percent: present ? Math.round(device.percentage) : 0
    readonly property bool low: present && !charging && percent <= 20

    visible: present
    spacing: 4

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.charging
        text: "⚡"
        font.pixelSize: Theme.fontSize - 2
        color: Theme.purple
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 11
        radius: 2
        color: "transparent"
        border.width: 1
        border.color: root.low ? Theme.red : Theme.textFaint

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

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.percent + "%"
        font.family: Theme.monoFamily
        font.pixelSize: Theme.fontSize - 1
        color: root.low ? Theme.red : Theme.textMuted
    }
}
