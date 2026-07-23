pragma Singleton
import Quickshell
import QtQuick

// Eternal Darkness design tokens: high-contrast black and red, purple as a
// strictly tertiary accent. Every module styles through these — no literal
// colors in widgets — so the M4 theme.json hot-reload only has to touch this
// file's bindings.
Singleton {
    // grounds
    readonly property color ground: "#0a0709"
    readonly property color surface: "#161013"
    readonly property color surfaceRaised: "#1e161a"
    readonly property color line: "#2e2228"

    // content
    readonly property color text: "#ece5e7"
    readonly property color textMuted: "#a3959b"
    readonly property color textFaint: "#6e6167"

    // accents
    readonly property color red: "#e0263c"
    readonly property color redDim: "#8f1e2d"
    readonly property color purple: "#a488c9"
    readonly property color purpleDim: "#4c3a63"

    // bar
    readonly property color barBg: Qt.rgba(0.039, 0.027, 0.035, 0.92)
    readonly property int barHeight: 32

    readonly property string fontFamily: "Noto Sans"
    readonly property string monoFamily: "monospace"
    readonly property int fontSize: 13
}
