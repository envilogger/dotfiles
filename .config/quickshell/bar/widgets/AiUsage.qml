import QtQuick
import Quickshell
import qs

// A dot per provider, lit when its plan limit runs low. Click: open AI usage panel
// (Claude personal, Claude work and ChatGPT limits, tokens per day).
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

    // One dot per provider, stacked down the right edge in the order of the panel's
    // tabs: personal Claude, work Claude, ChatGPT. Nothing shows below 50%, then the
    // dot appears green, turns yellow past 75% and red past 90%.
    Column {
        anchors.right: parent.right
        anchors.rightMargin: -4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: AiUsageData.providers

            Rectangle {
                required property string modelData
                readonly property real percent: AiUsageData.percents[modelData] ?? 0
                // Hidden rather than absent: the dots that are lit keep their place,
                // so which provider a dot stands for never shifts.
                opacity: percent > 50 ? 1 : 0
                width: 6
                height: 6
                radius: 3
                color: percent > 90 ? Theme.crit : percent > 75 ? Theme.warn : Theme.good
                border.color: Theme.bg
                border.width: 1
            }
        }
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
