import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

Item {
    id: root

    implicitWidth: Math.max(icon.width, timer.visible ? timer.implicitWidth : 0)
    implicitHeight: icon.height + (timer.visible ? timer.implicitHeight + 2 : 0)

    function openApp() {
        const window = Hyprland.toplevels.values.find(w =>
            [w.wayland?.appId, w.lastIpcObject?.class, w.lastIpcObject?.initialClass]
                .some(id => (id ?? "").toLowerCase() === "ticktick"));
        if (window) {
            window.workspace?.activate();
            window.wayland?.activate();
            return;
        }
        const entry = DesktopEntries.byId("ticktick") ?? DesktopEntries.heuristicLookup("TickTick");
        entry?.execute();
    }

    SvgIcon {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        name: "square-rounded-check"
        color: area.containsMouse ? Theme.accent : Theme.fg

        Rectangle {
            visible: TickTickData.active
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -2
            anchors.topMargin: -2
            width: 8
            height: 8
            radius: 4
            color: Theme.crit
            border.color: Theme.bg
            border.width: 1.5
        }
    }

    Text {
        id: timer
        visible: TickTickData.active
        anchors.top: icon.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.floor(TickTickData.remaining / 60) + ":"
            + String(TickTickData.remaining % 60).padStart(2, "0")
        color: area.containsMouse ? Theme.accent : TickTickData.paused ? Theme.warn : Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.smallFontSize
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.leftMargin: -(Theme.barWidth - root.width) / 2
        anchors.rightMargin: -(Theme.barWidth - root.width) / 2
        anchors.topMargin: -Theme.spacing / 2
        anchors.bottomMargin: -Theme.spacing / 2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openApp()
    }
}
