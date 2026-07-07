import QtQuick
import "../../services"

Text {
    id: root

    property var now: new Date()

    text: Qt.formatDateTime(now, "ddd d MMM  HH:mm")
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
