pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// NDJSON client for ShojiWM's IPC socket (see ShojiWM packages/shoji_wm/src/ipc.ts).
//
//   send:  { "method": string, "params"?: unknown }             fire-and-forget
//          { "id": number, "method": ..., "params": ... }       expects response
//   recv:  { "event": string, "payload": unknown }              broadcast
//          { "id": number, "result"|"error": ... }              response
//
// Strictly non-blocking: the Socket is async on the Qt event loop and QML
// renders on a separate thread, so a stalled compositor can never block a
// frame. The socket is recreated on ShojiWM config hot-reload; the reconnect
// timer below retries until it reappears, then re-fetches initial state.
Singleton {
    id: root

    readonly property string socketPath: {
        const runtimeDir = Quickshell.env("XDG_RUNTIME_DIR") || "/tmp";
        const display = Quickshell.env("WAYLAND_DISPLAY") || "wayland-0";
        return `${runtimeDir}/shojiwm-${display}.sock`;
    }

    // True once the first workspaces.get response has landed on the current
    // connection. The bar shows a health dot off this.
    property bool ready: false

    // Reactive state mirrored from broadcasts (same shape shoji-bar-2's
    // workspaceState.ts consumes).
    property var view: null                 // workspaces.changed / workspaces.get
    property var dockProximity: ({})        // connector -> bool
    property var snapPreview: ({})          // connector -> rect|null (moves to minka-fx in M3)

    // ui.* broadcasts (start menu toggles etc.) — wired up by M2 modules.
    signal uiEvent(string event, var payload)

    property int _nextId: 1
    property var _pending: ({})

    // Request with an id-correlated response. `onResult(result, error)` is
    // optional; without it the response is routed by well-known method below.
    function request(method, params, onResult) {
        const id = _nextId++;
        if (onResult)
            _pending[id] = onResult;
        _write(params === undefined ? { id, method } : { id, method, params });
    }

    // Fire-and-forget command.
    function send(method, params) {
        _write(params === undefined ? { method } : { method, params });
    }

    function activateWorkspace(monitorName, index) {
        send("workspaces.activate", { monitor: monitorName, index: index });
    }

    function toggleTiling(monitorName) {
        send("workspaces.toggleTiling", { monitor: monitorName });
    }

    function activateWindow(windowId) {
        send("windows.activate", { windowId: windowId });
    }

    function monitorView(connectorName) {
        const v = root.view;
        if (!v)
            return null;
        const matched = v.monitors.find(m => m.name === connectorName);
        if (matched)
            return matched;
        // Unknown connector: fall back like shoji-bar-2 does.
        return v.monitors.find(m => m.name === v.currentMonitor) ?? v.monitors[0] ?? null;
    }

    function _write(message) {
        if (!socket.connected)
            return;
        socket.write(JSON.stringify(message) + "\n");
        socket.flush();
    }

    function _handleMessage(message) {
        if (message.event !== undefined) {
            if (message.event === "workspaces.changed") {
                root.view = message.payload;
                root.ready = true;
            } else if (message.event === "dock.proximity") {
                const p = message.payload;
                const next = Object.assign({}, root.dockProximity);
                next[p.monitor] = p.inside;
                root.dockProximity = next;
            } else if (message.event === "snap.preview") {
                const p = message.payload;
                const next = Object.assign({}, root.snapPreview);
                next[p.monitor] = p.rect ? Object.assign({ kind: p.kind }, p.rect) : null;
                root.snapPreview = next;
            } else if (message.event.startsWith("ui.")) {
                root.uiEvent(message.event, message.payload);
            }
            return;
        }
        if (message.id !== undefined) {
            const callback = root._pending[message.id];
            if (callback) {
                delete root._pending[message.id];
                callback(message.result, message.error);
            } else if (message.result !== undefined) {
                // Un-tracked response: the initial workspaces.get.
                root.view = message.result;
                root.ready = true;
            }
        }
    }

    Socket {
        id: socket
        path: root.socketPath
        connected: true

        parser: SplitParser {
            onRead: line => {
                const trimmed = line.trim();
                if (trimmed.length === 0)
                    return;
                let message;
                try {
                    message = JSON.parse(trimmed);
                } catch (e) {
                    return; // ignore malformed lines
                }
                root._handleMessage(message);
            }
        }

        onConnectedChanged: {
            if (connected) {
                root._pending = {};
                root.request("workspaces.get");
            } else {
                root.ready = false;
            }
        }

        // Connection refused / socket gone (config reload window): the
        // reconnect timer below picks it up.
        onError: root.ready = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: !socket.connected
        onTriggered: socket.connected = true
    }
}
