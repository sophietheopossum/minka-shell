import Quickshell
import "services"
import "modules/bar"
import "modules/dock"
import "modules/startmenu"
import "modules/notifications"

// Minka shell entry point. One surface set per output; ShellLayout decides
// which outputs show persistent surfaces (Duo mode pins them to the
// ScreenPad), MenuState routes menu open/close across outputs.
ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            id: scope

            required property var modelData

            Bar {
                modelData: scope.modelData
            }

            Dock {
                modelData: scope.modelData
            }

            StartMenu {
                modelData: scope.modelData
            }

            NotifPopup {
                modelData: scope.modelData
            }
        }
    }
}
