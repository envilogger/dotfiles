import QtQuick
import Quickshell.Services.Pipewire
import qs

// Click: toggle mute. Scroll: adjust volume.
Icon {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property real volume: sink?.audio?.volume ?? 0

    // Required so the sink's audio properties are bound and kept live.
    PwObjectTracker { objects: [root.sink] }

    code: muted || volume <= 0 ? 0xf0581
        : volume < 0.34 ? 0xf057f
        : volume < 0.67 ? 0xf0580
        : 0xf057e
    color: muted ? Theme.muted : Theme.fg

    MouseArea {
        anchors.fill: parent
        onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
        onWheel: wheel => {
            if (!root.sink?.audio) return;
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step));
        }
    }
}
