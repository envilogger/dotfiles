import QtQuick
import Quickshell
import qs

// Bell with the number of notifications. Click: open the notification center.
// Right click: toggle "do not disturb".
SvgIcon {
    id: root

    readonly property int count: NotificationService.list.length

    name: NotificationService.dnd ? "bell-off" : "bell"
    color: area.containsMouse || panel.visible ? Theme.accent
        : NotificationService.dnd ? Theme.muted
        : Theme.fg

    // Count badge
    Rectangle {
        visible: root.count > 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -4
        anchors.rightMargin: -6
        width: Math.max(height, badge.implicitWidth + 6)
        height: 13
        radius: height / 2
        color: NotificationService.dnd ? Theme.overlay : Theme.accent

        Text {
            id: badge
            anchors.centerIn: parent
            text: root.count > 9 ? "9+" : root.count
            color: Theme.bg
            font.family: Theme.font
            font.pixelSize: Theme.smallFontSize - 1
            font.bold: true
        }
    }

    // When the panel was open, clicking the icon first dismisses it via the focus grab;
    // don't let that same click reopen it.
    property real panelClosedAt: 0

    function togglePanel() {
        if (panel.visible) {
            panel.visible = false;
            return;
        }
        if (Date.now() - panelClosedAt < 300) return;
        panel.anchor.rect.y = root.mapToItem(null, 0, root.height).y;
        panel.visible = true;
    }

    MouseArea {
        id: area
        // Larger than the glyph: the full bar width, and half the gap to neighbouring widgets.
        anchors.fill: parent
        anchors.leftMargin: -(Theme.barWidth - root.width) / 2
        anchors.rightMargin: -(Theme.barWidth - root.width) / 2
        anchors.topMargin: -Theme.spacing / 2
        anchors.bottomMargin: -Theme.spacing / 2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) NotificationService.setDnd(!NotificationService.dnd);
            else root.togglePanel();
        }
    }

    NotificationsPanel {
        id: panel
        onVisibleChanged: if (!visible) root.panelClosedAt = Date.now()
        maxHeight: (root.QsWindow.window?.screen?.height ?? 1080) * Theme.panelMaxHeight

        // Open to the right of the bar, growing upwards from the icon's bottom edge.
        anchor.window: root.QsWindow.window
        anchor.rect.x: Theme.barWidth + 8
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Top | Edges.Right
    }
}
