import QtQuick
import Quickshell.Io
import "../../services"

// CPU / RAM readout sampled from /proc every 3s via one short-lived shell
// process (async; no render-loop involvement). CPU% is the delta between
// consecutive /proc/stat samples.
Row {
    id: root

    property real cpuPercent: 0
    property real memPercent: 0

    property var _prev: null // [totalJiffies, idleJiffies]
    property real _memTotal: 0

    spacing: 10

    function _ingest(line) {
        const parts = line.trim().split(/\s+/);
        if (parts[0] === "cpu") {
            const values = parts.slice(1).map(Number);
            const idle = values[3] + (values[4] || 0); // idle + iowait
            const total = values.reduce((a, b) => a + (b || 0), 0);
            if (root._prev !== null) {
                const dTotal = total - root._prev[0];
                const dIdle = idle - root._prev[1];
                if (dTotal > 0)
                    root.cpuPercent = 100 * (1 - dIdle / dTotal);
            }
            root._prev = [total, idle];
        } else if (parts[0] === "MemTotal:") {
            root._memTotal = Number(parts[1]);
        } else if (parts[0] === "MemAvailable:" && root._memTotal > 0) {
            root.memPercent = 100 * (1 - Number(parts[1]) / root._memTotal);
        }
    }

    Process {
        id: sampler
        command: ["sh", "-c", "head -n1 /proc/stat && grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        stdout: SplitParser {
            onRead: line => root._ingest(line)
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: sampler.running = true
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "cpu " + Math.round(root.cpuPercent) + "%"
        font.family: Theme.monoFamily
        font.pixelSize: Theme.fontSize - 2
        color: root.cpuPercent >= 90 ? Theme.red : Theme.textFaint
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "mem " + Math.round(root.memPercent) + "%"
        font.family: Theme.monoFamily
        font.pixelSize: Theme.fontSize - 2
        color: root.memPercent >= 90 ? Theme.red : Theme.textFaint
    }
}
