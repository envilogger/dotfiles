import QtQuick
import Quickshell
import qs

// Dot when a plan limit runs low. Click: open AI usage panel (Claude and ChatGPT
// limits, tokens per day).
SvgIcon {
    id: root

    name: "settings-ai"
    color: area.containsMouse || panel.visible ? Theme.accent : Theme.fg

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

    // Notification dot once a limit passes 70% (yellow) or 90% (red).
    Rectangle {
        readonly property real percent: AiUsageData.maxPercent
        visible: percent > 70
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -2
        anchors.topMargin: -2
        width: 8
        height: 8
        radius: 4
        color: percent > 90 ? Theme.crit : Theme.warn
        border.color: Theme.bg
        border.width: 1.5
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
        onClicked: root.togglePanel()
    }

    AiUsagePanel {
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
