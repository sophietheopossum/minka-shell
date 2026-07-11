import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"

// Per-output wallpaper on the wlr-layer-shell background layer. The image
// path follows shell.wallpaper in minka-settings.json via ShellLayout's
// settings watch, so picking a wallpaper in MinkaConf lands live. With no
// wallpaper configured the surface is unmapped entirely and the
// compositor's own background shows through.
PanelWindow {
    id: root

    required property var modelData

    screen: modelData
    visible: ShellLayout.wallpaper !== ""

    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "black"

    Image {
        anchors.fill: parent
        source: ShellLayout.wallpaper === "" ? "" : "file://" + ShellLayout.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }
}