import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

// Notification center: "do not disturb" switch, clear all, and every notification
// not yet dismissed, newest first. Opening it hides the popups.
PopupWindow {
    id: root

    // Tallest the panel may get before its contents scroll.
    property real maxHeight: 800

    readonly property int margin: Theme.padding + 2

    implicitWidth: 400
    implicitHeight: Math.min(maxHeight, content.implicitHeight + 2 * margin)
    color: "transparent"

    // Close when clicking outside the panel. The grab is activated shortly after the
    // popup is shown: activating it before the popup surface is mapped leaves the popup
    // out of the grab, so the first click inside it would dismiss the panel.
    HyprlandFocusGrab {
        id: grab
        windows: [root]
        onCleared: root.visible = false
    }

    Timer {
        id: grabDelay
        interval: 100
        onTriggered: {
            grab.active = root.visible;
            if (root.visible) frame.forceActiveFocus();
        }
    }

    onVisibleChanged: {
        if (visible) {
            grabDelay.restart();
            flick.contentY = 0;
            NotificationService.popups = [];
        } else {
            grab.active = false;
        }
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.surface
        border.width: 2
        focus: true
        Keys.onEscapePressed: root.visible = false

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: root.margin
            contentHeight: content.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: content
                width: flick.width
                spacing: 8

                // Title, clear all
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 12

                    SvgIcon {
                        name: NotificationService.dnd ? "bell-off" : "bell"
                        color: NotificationService.dnd ? Theme.muted : Theme.accent
                        size: Theme.iconSize + 6
                        Layout.preferredWidth: 28
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Notifications"
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 1
                            font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: NotificationService.list.length === 0 ? "Nothing new"
                                : NotificationService.list.length === 1 ? "1 notification"
                                : NotificationService.list.length + " notifications"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    Text {
                        visible: NotificationService.list.length > 0
                        text: "Clear all"
                        color: clearArea.containsMouse ? Theme.accent : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.clearAll()
                        }
                    }
                }

                // Do not disturb
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: "Do not disturb"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }

                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 20
                        radius: 10
                        color: NotificationService.dnd ? Theme.accent : Theme.overlay

                        Rectangle {
                            x: NotificationService.dnd ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            radius: 7
                            color: NotificationService.dnd ? Theme.bg : Theme.fg
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.setDnd(!NotificationService.dnd)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    implicitHeight: 1
                    color: Theme.overlay
                }

                Text {
                    visible: NotificationService.list.length === 0
                    text: "No notifications"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }

                Repeater {
                    model: ScriptModel { values: NotificationService.list }
                    NotificationCard {
                        required property var modelData
                        Layout.fillWidth: true
                        notification: modelData
                    }
                }
            }
        }

        // Scroll indicator, only when the contents overflow.
        Rectangle {
            visible: flick.contentHeight > flick.height
            anchors.right: parent.right
            anchors.rightMargin: 4
            y: flick.y + flick.visibleArea.yPosition * flick.height
            width: 3
            height: flick.visibleArea.heightRatio * flick.height
            radius: 1.5
            color: Theme.overlay
        }
    }
}
