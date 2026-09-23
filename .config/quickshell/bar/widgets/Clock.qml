import QtQuick
import Quickshell
import qs

// Hours stacked over minutes. Click: open calendar panel.
Item {
    id: root
    implicitWidth: digits.implicitWidth
    implicitHeight: digits.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    component Digits: Text {
        anchors.horizontalCenter: parent.horizontalCenter
        color: area.containsMouse || panel.visible ? Theme.accent : Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 4
        font.bold: true
    }

    Column {
        id: digits
        anchors.centerIn: parent
        spacing: -2

        Digits { text: Qt.formatDateTime(clock.date, "HH") }
        Digits { text: Qt.formatDateTime(clock.date, "mm") }
    }

    // When the panel was open, clicking the clock first dismisses it via the focus grab;
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
        // Larger than the digits: the full bar width, and half the gap to neighbouring widgets.
        anchors.fill: parent
        anchors.leftMargin: -(Theme.barWidth - root.width) / 2
        anchors.rightMargin: -(Theme.barWidth - root.width) / 2
        anchors.topMargin: -Theme.spacing / 2
        anchors.bottomMargin: -Theme.spacing / 2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
    }

    CalendarPanel {
        id: panel
        onVisibleChanged: if (!visible) root.panelClosedAt = Date.now()
        maxHeight: (root.QsWindow.window?.screen?.height ?? 1080) * Theme.panelMaxHeight

        // Open to the right of the bar, growing upwards from the clock's bottom edge.
        anchor.window: root.QsWindow.window
        anchor.rect.x: Theme.barWidth + 8
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Top | Edges.Right
    }
}
