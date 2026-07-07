pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Single org.freedesktop.Notifications server for the whole shell (must exist
// exactly once — popup windows per screen only render this model).
Singleton {
    id: root

    readonly property var tracked: server.trackedNotifications

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodySupported: true

        onNotification: notification => {
            notification.tracked = true;
        }
    }
}
