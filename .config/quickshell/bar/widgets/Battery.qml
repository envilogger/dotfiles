import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// Tabler battery icon in five fill steps, or with a bolt while plugged in. Grey above
// 40%, yellow at 20-40%, red below 20%. Click: open battery panel.
SvgIcon {
    id: root

    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property real level: Math.max(0, Math.min(1, dev?.percentage ?? 0))
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
        || dev?.state === UPowerDeviceState.PendingCharge
        || dev?.state === UPowerDeviceState.FullyCharged
    readonly property color levelColor: level < 0.2 ? Theme.crit
        : level < 0.4 ? Theme.warn
        : Theme.fg

    visible: dev?.isPresent ?? false
    name: charging ? "battery-charging"
        : level < 0.125 ? "battery"
        : level < 0.375 ? "battery-1"
        : level < 0.625 ? "battery-2"
        : level < 0.875 ? "battery-3"
        : "battery-4"
    // Accent while hovered or the panel is open, like the other bar widgets.
    color: area.containsMouse || panel.visible ? Theme.accent : levelColor

    // When the panel was open, clicking the battery first dismisses it via the focus grab;
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
        // Larger than the battery: the full bar width, and half the gap to neighbouring widgets.
        anchors.fill: parent
        anchors.leftMargin: -(Theme.barWidth - root.width) / 2
        anchors.rightMargin: -(Theme.barWidth - root.width) / 2
        anchors.topMargin: -Theme.spacing / 2
        anchors.bottomMargin: -Theme.spacing / 2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
    }

    BatteryPanel {
        id: panel
        onVisibleChanged: if (!visible) root.panelClosedAt = Date.now()
        maxHeight: (root.QsWindow.window?.screen?.height ?? 1080) * Theme.panelMaxHeight
        dev: root.dev

        // Open to the right of the bar, growing upwards from the battery's bottom edge.
        anchor.window: root.QsWindow.window
        anchor.rect.x: Theme.barWidth + 8
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Top | Edges.Right
    }
}
