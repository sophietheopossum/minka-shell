import Quickshell
import QtQuick
import "../../services"

// Application launcher, one per output; MenuState decides which instance is
// open (in Duo mode always the ScreenPad's). Opened by the bar button or the
// ui.startMenu IPC broadcast (Super+A / Super tap in the ShojiWM config).
PanelWindow {
    id: root

    required property var modelData

    readonly property bool open: MenuState.isOpen("start", modelData.name)
    property string query: ""

    // Search across everything a user might know the app by: display name,
    // description, desktop id, executable, and keywords. (Lesson from CMST:
    // its Name is "Connman UI Setup" — only Exec/id contain "cmst".)
    function entryMatches(entry, q) {
        const fields = [entry.name, entry.genericName, entry.comment, entry.id, entry.execString];
        if (entry.keywords)
            for (const keyword of entry.keywords)
                fields.push(keyword);
        return fields.some(f => f && String(f).toLowerCase().includes(q));
    }

    readonly property var apps: {
        const all = DesktopEntries.applications.values;
        const q = query.trim().toLowerCase();
        const list = q === "" ? all.slice() : all.filter(a => entryMatches(a, q));
        // Name-prefix hits first (so "fir" ranks Firefox above LibreOffice
        // Writer's comment), then alphabetical.
        list.sort((a, b) => {
            if (q !== "") {
                const aPrefix = a.name.toLowerCase().startsWith(q);
                const bPrefix = b.name.toLowerCase().startsWith(q);
                if (aPrefix !== bPrefix)
                    return aPrefix ? -1 : 1;
            }
            return a.name.localeCompare(b.name);
        });
        return list;
    }

    screen: modelData
    visible: open
    focusable: true
    anchors.top: true
    anchors.left: true
    margins.top: Theme.barHeight + 6
    margins.left: 6
    implicitWidth: 380
    implicitHeight: Math.min(560, modelData.height - Theme.barHeight - 24)
    exclusiveZone: 0
    color: "transparent"

    onOpenChanged: {
        if (open) {
            query = "";
            searchField.text = "";
            searchField.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.barBg
        border.width: 1
        border.color: Theme.line

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Search
            Rectangle {
                width: parent.width
                height: 32
                radius: 6
                color: Theme.surfaceRaised
                border.width: 1
                border.color: searchField.activeFocus ? Theme.red : Theme.line

                TextInput {
                    id: searchField
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Theme.text
                    clip: true
                    onTextChanged: root.query = text
                    Keys.onEscapePressed: MenuState.closeAll()
                    Keys.onReturnPressed: {
                        if (root.apps.length > 0) {
                            root.apps[0].execute();
                            MenuState.closeAll();
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchField.text === ""
                        text: "search…"
                        font: searchField.font
                        color: Theme.textFaint
                    }
                }
            }

            // App list
            ListView {
                width: parent.width
                height: parent.height - 32 - 36 - 2 * parent.spacing
                clip: true
                model: root.apps
                spacing: 2

                delegate: Rectangle {
                    id: appRow

                    required property var modelData

                    width: ListView.view.width
                    height: 36
                    radius: 6
                    color: rowArea.containsMouse ? Theme.surfaceRaised : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 10

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            sourceSize.width: 22
                            sourceSize.height: 22
                            fillMode: Image.PreserveAspectFit
                            source: appRow.modelData.icon
                                ? Quickshell.iconPath(appRow.modelData.icon, "application-x-executable")
                                : Quickshell.iconPath("application-x-executable")
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: appRow.modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.text
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            appRow.modelData.execute();
                            MenuState.closeAll();
                        }
                    }
                }
            }

            // Session controls
            Row {
                width: parent.width
                height: 30
                spacing: 8

                Repeater {
                    model: [
                        // Ends the whole login session (compositor included);
                        // the display manager takes over from there.
                        { label: "logout", command: ["sh", "-c", "loginctl terminate-session \"$XDG_SESSION_ID\""] },
                        { label: "sleep", command: ["systemctl", "suspend"] },
                        { label: "reboot", command: ["systemctl", "reboot"] },
                        { label: "off", command: ["systemctl", "poweroff"] }
                    ]

                    delegate: Rectangle {
                        id: powerButton

                        required property var modelData

                        width: 64
                        height: 28
                        radius: 6
                        color: powerArea.containsMouse ? Theme.redDim : Theme.surfaceRaised
                        border.width: 1
                        border.color: powerArea.containsMouse ? Theme.red : Theme.line

                        Text {
                            anchors.centerIn: parent
                            text: powerButton.modelData.label
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontSize - 2
                            color: powerArea.containsMouse ? Theme.text : Theme.textMuted
                        }

                        MouseArea {
                            id: powerArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(powerButton.modelData.command)
                        }
                    }
                }
            }
        }
    }
}
