import QtQuick
import Quickshell
import Quickshell.Networking
import qs

// Click: open network panel.
Icon {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifi: wifiDevice?.connected ? wifiDevice : null
    readonly property var wifiNet: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property real strength: wifiNet?.signalStrength ?? 0

    code: wired ? 0xf0200
        : !wifi ? 0xf05aa
        : strength < 0.2 ? 0xf092e
        : strength < 0.4 ? 0xf091f
        : strength < 0.6 ? 0xf0922
        : strength < 0.8 ? 0xf0925
        : 0xf0928
    color: area.containsMouse || panel.visible ? Theme.accent
        : wired || wifi ? Theme.fg
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
        onClicked: root.togglePanel()
    }

    NetworkPanel {
        id: panel
        onVisibleChanged: if (!visible) root.panelClosedAt = Date.now()
        maxHeight: (root.QsWindow.window?.screen?.height ?? 1080) * Theme.panelMaxHeight

        device: root.wired ?? root.wifi
        wifiDevice: root.wifiDevice
        wifiNet: root.wifiNet
        iconCode: root.code

        // Open to the right of the bar, growing upwards from the icon's bottom edge.
        anchor.window: root.QsWindow.window
        anchor.rect.x: Theme.barWidth + 8
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Top | Edges.Right
    }
}
