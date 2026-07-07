pragma Singleton
import Quickshell
import QtQuick

// Monitor role policy. Duo mode (ARCH_MAP requirement 3): when the UX482
// ScreenPad (1920x515) is connected, all persistent shell surfaces pin to it
// and the main display stays clear for application windows. On any other
// machine every output gets the KDE-style layout.
Singleton {
    // The ScreenPad presents as a wide, very short output. Match on shape
    // rather than connector name so docks/adapters don't break detection.
    function isScreenPad(screen) {
        return screen !== null && screen.height <= 600 && screen.width >= 1600;
    }

    readonly property bool duoMode: Quickshell.screens.some(s => isScreenPad(s))

    function showBarOn(screen) {
        return duoMode ? isScreenPad(screen) : true;
    }
}
