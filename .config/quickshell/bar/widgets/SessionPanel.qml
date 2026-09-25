import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

// Popup with session actions: lock, log out, reboot, shut down.
PopupWindow {
    id: root

    // Same commands as the keybinds in hyprland.lua. hyprshutdown closes apps
    // gracefully before leaving Hyprland; systemctl/hyprctl are the fallbacks.
    readonly property var actions: [
        {
            label: "Lock",
            icon: "lock",
            cmd: "pidof hyprlock || systemd-inhibit --what=idle:sleep --who=hyprlock --why='Screen locked' hyprlock"
        },
        {
            label: "Log out",
            icon: "logout",
            cmd: "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
        },
        {
            label: "Reboot",
            icon: "refresh",
            cmd: "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown -t 'Rebooting...' -p 'systemctl reboot' || systemctl reboot"
        },
        {
            label: "Shut down",
            icon: "power",
            crit: true,
            cmd: "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown -p 'systemctl poweroff' || systemctl poweroff"
        }
    ]

    readonly property int margin: Theme.padding - 4

    function run(action) {
        root.visible = false;
        Quickshell.execDetached(["sh", "-c", action.cmd]);
    }

    implicitWidth: 180
    implicitHeight: content.implicitHeight + 2 * margin
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
        if (visible) grabDelay.restart();
        else grab.active = false;
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

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: root.margin
            spacing: 2

            Repeater {
                model: root.actions

                Rectangle {
                    id: row
                    required property var modelData
                    readonly property color tint: mouse.containsMouse
                        ? (modelData.crit ? Theme.crit : Theme.accent)
                        : Theme.fg

                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 6
                    color: mouse.containsMouse ? Theme.overlay : "transparent"

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(row.modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        SvgIcon {
                            name: row.modelData.icon
                            color: row.tint
                        }
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.label
                            color: row.tint
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                    }
                }
            }
        }
    }
}
