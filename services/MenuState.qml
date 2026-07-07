pragma Singleton
import Quickshell
import QtQuick

// Cross-window menu state: bar buttons and ui.* IPC broadcasts both funnel
// through here, and menu windows bind their visibility to it. In Duo mode
// menus always open on the ScreenPad regardless of which monitor triggered
// them (ARCH_MAP requirement 3).
Singleton {
    id: root

    // screen name -> bool
    property var startMenuOpen: ({})

    function _resolveTarget(connector) {
        if (ShellLayout.duoMode) {
            const pad = Quickshell.screens.find(s => ShellLayout.isScreenPad(s));
            if (pad)
                return pad.name;
        }
        if (connector && Quickshell.screens.some(s => s.name === connector))
            return connector;
        const first = Quickshell.screens[0];
        return first ? first.name : "";
    }

    function startMenu(connector, action) {
        const target = _resolveTarget(connector);
        if (target === "")
            return;
        const next = Object.assign({}, startMenuOpen);
        const open = action === "toggle" ? !(next[target] === true) : action === "open";
        // Only one start menu at a time.
        for (const key in next)
            next[key] = false;
        next[target] = open;
        startMenuOpen = next;
    }

    function closeAll() {
        startMenu("", "close");
    }

    Connections {
        target: ShojiIpc

        function onUiEvent(event, payload) {
            if (event === "ui.startMenu")
                root.startMenu(payload ? payload.connector : null, payload && payload.action ? payload.action : "toggle");
        }
    }
}
