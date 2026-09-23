import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// Click: open Bluetooth panel. Right click: toggle the adapter's power.
SvgIcon {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

    name: !powered ? "bluetooth-off"
        : connected ? "bluetooth-connected"
        : "bluetooth"
    color: area.containsMouse || panel.visible ? Theme.accent
        : powered ? Theme.fg
        : Theme.muted

    // When the panel was open, clicking the icon first dismisses it via the focus grab;
    // don't let that same click reopen it.
    property real panelClosedAt: 0

    function togglePanel() {
        if (panel.visible) {
            panel.visible = false;
            return;
        }
        if (Date.now() - panelClosedAt < 300) return;
        // Pin the panel's position at open time; moving the anchor while open would
        // recreate (and close) the popup.
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
            if (mouse.button === Qt.RightButton) {
                if (root.adapter) root.adapter.enabled = !root.adapter.enabled;
            } else {
                root.togglePanel();
            }
        }
    }

    BluetoothPanel {
        id: panel
        onVisibleChanged: if (!visible) root.panelClosedAt = Date.now()
        maxHeight: (root.QsWindow.window?.screen?.height ?? 1080) * Theme.panelMaxHeight
        adapter: root.adapter

        // Open to the right of the bar, growing upwards from the icon's bottom edge.
        anchor.window: root.QsWindow.window
        anchor.rect.x: Theme.barWidth + 8
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Top | Edges.Right
    }
}
