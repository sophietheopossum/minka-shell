import Quickshell
import QtQuick
import "../../services"

// Self-rendered tray menu. Qt's platform-menu path (QsMenuAnchor /
// SystemTrayItem.display) proved unreliable on ShojiWM, so we read the DBus
// menu tree through QsMenuOpener and draw it ourselves — which also keeps it
// in the Eternal-Darkness theme instead of a foreign Qt popup.
//
// Two hard-won rules encoded here:
//  1. The popup window is sized ONCE at open and never resized while
//     mapped (the menu box grows inside a transparent window instead) —
//     resizing a mapped popup is compositor-hostile.
//  2. The root menu handle stays pinned by a dedicated opener for as long
//     as the popup is open. quickshell destroys the ENTIRE dbusmenu tree
//     when the root handle's refcount drops to zero (dbusmenu.cpp:
//     unrefHandle -> onMenuPathChanged -> deleteLater), so a lone opener
//     that navigates from the root into a child entry frees the very entry
//     it navigated to — the submenu flashes empty, then collapses. Layout
//     updates reuse items by id, so pinned entries survive them. Corollary:
//     openers must live at window scope, never inside delegates — a layout
//     update resets the model, tears down the delegate (and its opener),
//     and loops via AboutToShow.
PopupWindow {
    id: root

    property var menuHandle: null

    // Navigation stack of QsMenuEntry handles; empty = at the root menu.
    property var menuPath: []

    readonly property var currentMenu: menuPath.length > 0
        ? menuPath[menuPath.length - 1] : menuHandle

    property int fixedHeight: 440

    // Auto-dismiss when the pointer has left the menu box for a moment.
    property bool pointerInside: false

    visible: false
    implicitWidth: 260
    implicitHeight: fixedHeight
    color: "transparent"

    function openAt(window, x, y, handle) {
        menuHandle = handle;
        menuPath = [];
        anchor.window = window;
        anchor.rect.x = x;
        anchor.rect.y = y;
        // Everything below the bar down to the screen edge, capped: the
        // window must never change size while mapped.
        const screenHeight = window.screen ? window.screen.height : 600;
        fixedHeight = Math.max(120, Math.min(440, screenHeight - y - 16));
        visible = true;
    }

    function dismiss() {
        visible = false;
        menuHandle = null;
        menuPath = [];
    }

    function enter(entry) {
        menuPath = menuPath.concat([entry]);
    }

    function back() {
        menuPath = menuPath.slice(0, -1);
    }

    // Pin: holds a ref on the root handle for the popup's lifetime so the
    // tree (and any entry the nav opener points at) is never freed mid-use.
    QsMenuOpener {
        menu: root.menuHandle
    }

    // Nav: follows the navigation stack; renders whichever level is current.
    QsMenuOpener {
        id: opener

        menu: root.currentMenu
    }

    Timer {
        interval: 1200
        running: root.visible && !root.pointerInside
        onTriggered: root.dismiss()
    }

    // Transparent backdrop: a click anywhere outside the menu box closes.
    MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
    }

    Rectangle {
        id: menuBox

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Math.min(menuColumn.implicitHeight + 16, root.fixedHeight)
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

        Flickable {
            anchors.fill: parent
            anchors.margins: 8
            contentHeight: menuColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: menuColumn

                width: parent.width
                spacing: 1

                // Back row while inside a submenu.
                Rectangle {
                    visible: root.menuPath.length > 0
                    width: parent.width
                    height: 26
                    radius: 5
                    color: backArea.containsMouse ? Theme.surfaceRaised : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "‹"
                            font.pixelSize: Theme.fontSize
                            color: Theme.red
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "back"
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontSize - 2
                            color: Theme.textMuted
                        }
                    }

                    MouseArea {
                        id: backArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.back()
                    }
                }

                Rectangle {
                    visible: root.menuPath.length > 0
                    width: parent.width
                    height: 1
                    color: Theme.line
                }

                Repeater {
                    model: opener.children

                    delegate: Column {
                        id: entryBlock

                        required property var modelData

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
                                    visible: entryBlock.modelData.checkState === Qt.Checked
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
                                    width: Math.min(implicitWidth, menuColumn.width - 60)
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                visible: entryBlock.modelData.hasChildren
                                text: "▸"
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
                                        root.enter(entryBlock.modelData);
                                    } else {
                                        entryBlock.modelData.triggered();
                                        root.dismiss();
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: opener.children === null || opener.children.values.length === 0
                    text: root.menuPath.length > 0 ? "empty" : "no actions"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.textFaint
                }
            }
        }
    }
}
