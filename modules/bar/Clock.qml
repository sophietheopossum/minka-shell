import QtQuick
import "../../services"

Text {
    id: root

    property var now: new Date()

    // Sophie's preferred date format: D/M/YYYY, leading zeros stripped.
    text: Qt.formatDateTime(now, "d/M/yyyy  HH:mm")
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: Theme.text

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}
