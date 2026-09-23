import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs

// Mute toggle + volume slider + percentage for one Pipewire node.
RowLayout {
    id: root

    property PwNode node
    property int iconOn: 0xf057e
    property int iconOff: 0xf0581

    readonly property bool muted: node?.audio?.muted ?? true
    readonly property real volume: node?.audio?.volume ?? 0

    spacing: 10
    enabled: node?.audio != null

    Icon {
        code: root.muted ? root.iconOff : root.iconOn
        color: root.muted ? Theme.muted : Theme.fg
        Layout.preferredWidth: 20

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.node?.audio) root.node.audio.muted = !root.node.audio.muted
        }
    }

    Slider {
        Layout.fillWidth: true
        value: root.volume
        opacity: root.muted ? 0.5 : 1
        onMoved: v => { if (root.node?.audio) root.node.audio.volume = v; }
    }

    Text {
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.volume * 100) + "%"
        color: root.muted ? Theme.muted : Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }
}
