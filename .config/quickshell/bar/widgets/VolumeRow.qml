import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs

// Mute toggle + volume slider + percentage for one Pipewire node, or for a group of
// nodes controlled together (set `nodes` instead of `node`).
RowLayout {
    id: root

    property PwNode node
    property list<PwNode> nodes: node ? [node] : []
    property int iconOn: 0xf057e
    property int iconOff: 0xf0581

    readonly property var audios: nodes.map(n => n?.audio).filter(a => a)
    readonly property bool muted: audios.length === 0 || audios.every(a => a.muted)
    readonly property real volume: audios.reduce((max, a) => Math.max(max, a.volume), 0)

    spacing: 10
    enabled: audios.length > 0

    Icon {
        code: root.muted ? root.iconOff : root.iconOn
        color: root.muted ? Theme.muted : Theme.fg
        Layout.preferredWidth: 20

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const muted = !root.muted;
                for (const a of root.audios) a.muted = muted;
            }
        }
    }

    Slider {
        Layout.fillWidth: true
        value: root.volume
        opacity: root.muted ? 0.5 : 1
        onMoved: v => { for (const a of root.audios) a.volume = v; }
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
