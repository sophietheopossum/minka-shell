import QtQuick
import Quickshell.Services.Pipewire
import "../../services"

// Default-sink volume
// a tray-style icon applet: drawn speaker glyph, waves scale with level, ✕ when muted.
// Click opens the status menu; scroll adjusts ±5%; middle-click mutes.
Item {
    id: root

    property string monitorName: ""

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool present: sink !== null && sink.audio !== null
    readonly property bool muted: present && sink.audio.muted
    readonly property int percent: present ? Math.round(sink.audio.volume * 100) : 0

    visible: present
    width: 18
    height: 18

    onMutedChanged: icon.requestPaint()
    onPercentChanged: icon.requestPaint()

    // Node properties are invalid until the node is bound.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Canvas {
        id: icon

        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            // Rest at textFaint like the battery chrome so the hover jump
            // to full text brightness actually reads.
            const c = volumeArea.containsMouse ? Theme.text
                : Theme.textFaint;
            ctx.strokeStyle = c;
            ctx.fillStyle = c;
            ctx.lineWidth = 1.4;

            // Speaker body + cone.
            ctx.beginPath();
            ctx.moveTo(2, 7);
            ctx.lineTo(5, 7);
            ctx.lineTo(9, 3.5);
            ctx.lineTo(9, 14.5);
            ctx.lineTo(5, 11);
            ctx.lineTo(2, 11);
            ctx.closePath();
            ctx.fill();

            if (root.muted) {
                ctx.beginPath();
                ctx.moveTo(11.5, 6.5);
                ctx.lineTo(16, 11.5);
                ctx.moveTo(16, 6.5);
                ctx.lineTo(11.5, 11.5);
                ctx.stroke();
            } else {
                ctx.beginPath();
                ctx.arc(9, 9, 3.5, -Math.PI / 4, Math.PI / 4);
                ctx.stroke();
                if (root.percent > 50) {
                    ctx.beginPath();
                    ctx.arc(9, 9, 6, -Math.PI / 4, Math.PI / 4);
                    ctx.stroke();
                }
            }
        }
    }

    MouseArea {
        id: volumeArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onContainsMouseChanged: icon.requestPaint()
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