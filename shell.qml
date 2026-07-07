import Quickshell
import "services"
import "modules/bar"

// Minka shell entry point. One Bar per output; ShellLayout decides which
// outputs actually show persistent surfaces (Duo mode pins them to the
// ScreenPad). Menus, dock, tray land here in M2.
ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
