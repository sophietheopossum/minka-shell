import QtQuick
import Quickshell.Services.Pipewire
import "../../services"

// Default-sink volume readout, matching the mono cpu/mem aesthetic.
// Click opens the status menu; scroll adjusts ±5%; middle-click mutes.
Item {
    id: root

    required property string monitorName

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool present: sink !== null && sink.audio !== null
    readonly property bool muted: present && sink.audio.muted
    readonly property int percent: present ? Math.round(sink.audio.volume * 100) : 0

    visible: present
    width: label.implicitWidth
    height: label.implicitHeight

    // Node properties are invalid until the node is bound.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Text {
        id: label
        text: root.muted ? "vol ✕" : "vol " + root.percent + "%"
        font.family: Theme.monoFamily
        font.pixelSize: Theme.fontSize - 2
        color: root.muted ? Theme.textFaint
             : volumeArea.containsMouse ? Theme.text
             : Theme.textFaint
    }

    MouseArea {
        id: volumeArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                root.sink.audio.muted = !root.sink.audio.muted;
            else
                MenuState.toggle("status", root.monitorName);
        }
        onWheel: wheel => {
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step));
        }
    }
}
