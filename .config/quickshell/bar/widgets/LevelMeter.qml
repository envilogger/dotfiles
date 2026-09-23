import QtQuick
import Quickshell.Services.Pipewire
import qs

// Live signal level of a Pipewire node, drawn as a thin bar on a -60..0 dB scale.
Item {
    id: root

    property PwNode node
    property bool active: true

    // Linear peak mapped to dB so quiet signals are still visible.
    readonly property real level: {
        const peak = monitor.peak;
        if (!(peak > 0)) return 0;
        return Math.max(0, Math.min(1, (20 * Math.log10(peak) + 60) / 60));
    }

    implicitHeight: 3
    implicitWidth: 120

    PwNodePeakMonitor {
        id: monitor
        node: root.node
        enabled: root.active && root.node != null
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface
    }

    Rectangle {
        height: parent.height
        width: root.level * parent.width
        radius: height / 2
        color: root.level > 0.95 ? Theme.crit : root.level > 0.8 ? Theme.warn : Theme.good

        Behavior on width {
            NumberAnimation { duration: 80 }
        }
    }
}
