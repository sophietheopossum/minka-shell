pragma Singleton
import Quickshell
import QtQuick

// Cross-window menu state: bar buttons and ui.* IPC broadcasts both funnel
// through here, and menu windows bind their visibility to it. One menu open
// at a time shell-wide.
// In Duo mode the bar dropdowns open on the ScreenPad
// with the bar itself (ARCH_MAP requirement 3)
// the start menu follows the cursor: Super opens it on whichever display the pointer is on.
Singleton {
    id: root

    // screen name -> menu id (
    // "start" | 
    // "calendar" | 
    // "status" | 
    // "battery" | 
    // ""
    // )
    property var openMenu: ({})

    function isOpen(menu, screenName) {
        return openMenu[screenName] === menu;
    }

    // True while a bar dropdown is open. Excludes the start menu, which is
    // fullscreen and handles its own click-away dismissal.
    readonly property bool dropdownOpen: {
        for (const name in openMenu)
            if (openMenu[name] && openMenu[name] !== "start")
                return true;
        return false;
    }

    function _resolveTarget(
        menu, 
        connector,
    ) {
        if (
            ShellLayout.duoMode
            &&
            menu !== "start"
        ) {
            const pad = Quickshell.screens.find(s => ShellLayout.isScreenPad(s));
            if (pad)
                return pad.name;
        }
        if (connector && Quickshell.screens.some(s => s.name === connector))
            return connector;
        const first = Quickshell.screens[0];
        return first ? first.name : "";
    }

    function toggle(menu, connector, action) {
        const target = _resolveTarget(
            menu,
            connector,
        );
        if (target === "")
            return;
        const act = action === undefined ? "toggle" : action;
        const wasOpen = openMenu[target] === menu;
        const open = act === "toggle" ? !wasOpen : act === "open";
        const next = {};
        next[target] = open ? menu : "";
        openMenu = next;
    }

    function closeAll() {
        openMenu = {};
    }

    Connections {
        target: ShojiIpc

        function onUiEvent(event, payload) {
            // ui.startMenu { connector, action } — from the ShojiWM config
            // keybindings (Super+A / Super tap).
            if (event === "ui.startMenu")
                root.toggle("start", payload ? payload.connector : null, payload && payload.action ? payload.action : "toggle");
        }
    }
}
