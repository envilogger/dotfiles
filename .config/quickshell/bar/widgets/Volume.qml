import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// Click: open volume panel. Right click: toggle mute. Scroll: adjust volume.
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

    // When the panel was open, clicking the icon first dismisses it via the focus grab;
    // don't let that same click reopen it.
    property real panelClosedAt: 0

    function togglePanel() {
        if (panel.visible) {
            panel.visible = false;
            return;
        }
        if (Date.now() - panelClosedAt < 300) return;
        // Pin the panel's position at open time; the icon's width changes with the
        // volume glyph, and moving the anchor would recreate (and close) the popup.
        panel.anchor.rect.y = root.mapToItem(null, 0, root.height).y;
        panel.visible = true;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted;
            } else {
                root.togglePanel();
            }
        }
        onWheel: wheel => {
            if (!root.sink?.audio) return;
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step));
        }
    }

    VolumePanel {
        id: panel
        onVisibleChanged: if (!visible) root.panelClosedAt = Date.now()

        // Open to the right of the bar, growing upwards from the icon's bottom edge.
        anchor.window: root.QsWindow.window
        anchor.rect.x: Theme.barWidth + 8
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Top | Edges.Right
    }
}
