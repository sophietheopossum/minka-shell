pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Monitor role policy. Duo mode (ARCH_MAP requirement 3):
// when active, all persistent shell surfaces pin to the UX482 ScreenPad (1920x515) and the
// main display stays clear for application windows.
// In the general layout every output gets the KDE-style treatment.
//
// The mode follows `shell.layout` in minka-settings.json ("duo" | "general",
// switched live from MinkaConf's layout page); absent or "auto" falls back
// to hardware detection, which is also the effective first-run default when
// no settings file exists yet.
Singleton {
    id: root

    // The ScreenPad presents as a wide, very short output. Match on shape
    // rather than connector name so docks/adapters don't break detection.
    function isScreenPad(screen) {
        return screen !== null && screen.height <= 600 && screen.width >= 1600;
    }

    readonly property bool screenPadPresent: Quickshell.screens.some(s => isScreenPad(s))

    // "auto" | "duo" | "general" — anything unrecognized is treated as auto.
    property string configuredLayout: "auto"

    readonly property bool duoMode: configuredLayout === "duo" ? true
                                  : configuredLayout === "general" ? false
                                  : screenPadPresent

    function showBarOn(screen) {
        if (!duoMode)
            return true;
        // Duo forced with no matching output must not leave the session
        // without any shell surfaces at all.
        return screenPadPresent ? isScreenPad(screen) : true;
    }

    FileView {
        id: settingsFile

        path: Quickshell.env("HOME") + "/.config/shojiwm/src/minka-settings.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(settingsFile.text());
                const layout = data && data.shell ? data.shell.layout : undefined;
                root.configuredLayout =
                    layout === "duo" || layout === "general" ? layout : "auto";
            } catch (e) {
                root.configuredLayout = "auto";
            }
        }
    }
}