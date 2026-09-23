import QtQuick
import qs

// Horizontal 0..1 slider. Drag, click or scroll to change; emits `moved`.
Item {
    id: root

    property real value: 0
    signal moved(real value)

    implicitHeight: 16
    implicitWidth: 120

    function setFromX(x) {
        root.moved(Math.max(0, Math.min(1, x / width)));
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.overlay
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(1, root.value) * parent.width
        height: track.height
        radius: track.radius
        color: Theme.accent
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: Math.min(1, root.value) * (parent.width - width)
        width: mouse.containsMouse || mouse.pressed ? 14 : 12
        height: width
        radius: width / 2
        color: Theme.fg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onPressed: e => root.setFromX(e.x)
        onPositionChanged: e => { if (pressed) root.setFromX(e.x); }
        onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
