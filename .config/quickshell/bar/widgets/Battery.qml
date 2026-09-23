import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// Horizontal battery: outline filled to the charge level. Grey above 40%, yellow at
// 20-40%, red below 20%; a bolt is shown while charging. Click: open battery panel.
Item {
    id: root

    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property real level: Math.max(0, Math.min(1, dev?.percentage ?? 0))
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
        || dev?.state === UPowerDeviceState.PendingCharge
        || dev?.state === UPowerDeviceState.FullyCharged
    readonly property color levelColor: level < 0.2 ? Theme.crit
        : level < 0.4 ? Theme.warn
        : Theme.fg
    // Accent while hovered or the panel is open, like the other bar widgets.
    readonly property color iconColor: area.containsMouse || panel.visible ? Theme.accent : levelColor

    visible: dev?.isPresent ?? false
    implicitWidth: body.width + nub.width
    implicitHeight: body.height

    Rectangle {
        id: body
        width: 24
        height: 13
        radius: 3
        color: "transparent"
        border.color: root.iconColor
        border.width: 1.5

        Rectangle {
            x: 3
            y: 3
            width: (parent.width - 6) * root.level
            height: parent.height - 6
            radius: 1
            color: root.iconColor
        }
    }

    Rectangle {
        id: nub
        anchors.left: body.right
        anchors.verticalCenter: body.verticalCenter
        width: 2
        height: 5
        radius: 1
        color: root.iconColor
    }

    // Charging bolt, outlined in the bar colour so it reads over the fill.
    Icon {
        visible: root.charging
        anchors.centerIn: body
        code: 0xf140b
        font.pixelSize: 13
        color: Theme.bg
        style: Text.Outline
        styleColor: Theme.bg
    }
    Icon {
        visible: root.charging
        anchors.centerIn: body
        code: 0xf140b
        font.pixelSize: 11
        color: Theme.fg
    }

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
