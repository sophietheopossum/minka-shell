import Quickshell
import QtQuick
import "../../services"

// Self-rendered tray menu. Qt's platform-menu path (QsMenuAnchor /
// SystemTrayItem.display) proved unreliable on ShojiWM, so we read the DBus
// menu tree through QsMenuOpener and draw it ourselves — which also keeps it
// in the Eternal-Darkness theme instead of a foreign Qt popup. One submenu
// level expands inline (StatusNotifier menus are shallow in practice).
PopupWindow {
    id: root

    property var menuHandle: null

    // Auto-dismiss when the pointer has left the menu for a moment.
    property bool pointerInside: false

    visible: false
    implicitWidth: 240
    implicitHeight: Math.max(40, menuColumn.implicitHeight + 16)
    color: "transparent"

    function openAt(window, x, y, handle) {
        menuHandle = handle;
        anchor.window = window;
        anchor.rect.x = x;
        anchor.rect.y = y;
        visible = true;
    }

    function dismiss() {
        visible = false;
        menuHandle = null;
    }

    QsMenuOpener {
        id: opener

        menu: root.menuHandle
    }

    Timer {
        interval: 1200
        running: root.visible && !root.pointerInside
        onTriggered: root.dismiss()
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.barBg
        border.width: 1
        border.color: Theme.line

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.pointerInside = true
            onExited: root.pointerInside = false
            // Only tracks enter/leave; clicks fall through to the rows.
            acceptedButtons: Qt.NoButton
        }

        Column {
            id: menuColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 1

            Repeater {
                model: opener.children

                delegate: Column {
                    id: entryBlock

                    required property var modelData

                    property bool subOpen: false

                    width: menuColumn.width

                    // Separator
                    Rectangle {
                        visible: entryBlock.modelData.isSeparator
                        width: parent.width
                        height: 1
                        color: Theme.line
                    }

                    // Regular entry
                    Rectangle {
                        visible: !entryBlock.modelData.isSeparator
                        width: parent.width
                        height: 26
                        radius: 5
                        color: entryArea.containsMouse && entryBlock.modelData.enabled
                            ? Theme.surfaceRaised : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: entryBlock.modelData.checkState !== undefined
                                    && entryBlock.modelData.checkState === Qt.Checked
                                text: "✓"
                                font.pixelSize: Theme.fontSize - 2
                                color: Theme.red
                            }

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: source != ""
                                source: entryBlock.modelData.icon || ""
                                width: 14
                                height: 14
                                sourceSize.width: 14
                                sourceSize.height: 14
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: entryBlock.modelData.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                color: entryBlock.modelData.enabled ? Theme.text : Theme.textFaint
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth, menuColumn.width - 50)
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            visible: entryBlock.modelData.hasChildren
                            text: entryBlock.subOpen ? "▾" : "▸"
                            font.pixelSize: Theme.fontSize - 3
                            color: Theme.textFaint
                        }

                        MouseArea {
                            id: entryArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: entryBlock.modelData.enabled
                            onClicked: {
                                if (entryBlock.modelData.hasChildren) {
                                    entryBlock.subOpen = !entryBlock.subOpen;
                                } else {
                                    entryBlock.modelData.triggered();
                                    root.dismiss();
                                }
                            }
                        }
                    }

                    // Inline submenu (one level)
                    QsMenuOpener {
                        id: subOpener

                        menu: entryBlock.subOpen ? entryBlock.modelData : null
                    }

                    Column {
                        visible: entryBlock.subOpen
                        width: parent.width
                        spacing: 1

                        Repeater {
                            model: entryBlock.subOpen ? subOpener.children : null

                            delegate: Rectangle {
                                id: subEntry

                                required property var modelData

                                width: menuColumn.width
                                height: modelData.isSeparator ? 5 : 24
                                radius: 5
                                color: subArea.containsMouse && subEntry.modelData.enabled
                                    ? Theme.surfaceRaised : "transparent"

                                Rectangle {
                                    visible: subEntry.modelData.isSeparator
                                    anchors.centerIn: parent
                                    width: parent.width - 24
                                    height: 1
                                    color: Theme.line
                                }

                                Text {
                                    visible: !subEntry.modelData.isSeparator
                                    anchors.left: parent.left
                                    anchors.leftMargin: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: subEntry.modelData.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 2
                                    color: subEntry.modelData.enabled ? Theme.textMuted : Theme.textFaint
                                    elide: Text.ElideRight
                                    width: parent.width - 32
                                }

                                MouseArea {
                                    id: subArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !subEntry.modelData.isSeparator && subEntry.modelData.enabled
                                    onClicked: {
                                        subEntry.modelData.triggered();
                                        root.dismiss();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: opener.children === null || opener.children.values.length === 0
                text: "no actions"
                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontSize - 2
                color: Theme.textFaint
            }
        }
    }
}
