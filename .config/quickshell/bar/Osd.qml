import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.widgets

// On-screen display for volume, microphone mute and brightness, at the bottom of the
// focused monitor. Volume and mute follow Pipewire; brightness is shown on
// `qs ipc -c bar call osd brightness` (the brightness keys in hyprland.lua).
PanelWindow {
    id: root

    property string icon: "volume"
    // null: no level, just the icon and the label
    property var level: null
    property string label: ""
    property bool dim: false

    function show(icon: string, level: var, label: string, dim: bool) {
        root.icon = icon;
        root.level = level;
        root.label = label;
        root.dim = dim;
        root.visible = true;
        hide.restart();
    }

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.visible = false
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: false

    anchors.bottom: true
    margins.bottom: 80
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    // Clicks go through
    mask: Region {}

    implicitWidth: 300
    implicitHeight: 52
    color: "transparent"

    // Volume and mute

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    PwObjectTracker { objects: [root.sink, root.source] }

    // Ignore the initial values, and the jump when the default device changes.
    property bool ready: false
    Timer {
        id: settle
        running: true
        interval: 1000
        onTriggered: root.ready = true
    }
    onSinkChanged: { ready = false; settle.restart(); }
    onSourceChanged: { ready = false; settle.restart(); }

    function showVolume() {
        const audio = sink?.audio;
        if (!ready || !audio) return;
        const icon = audio.muted || audio.volume <= 0 ? "volume-3" : audio.volume < 0.5 ? "volume-2" : "volume";
        show(icon, audio.volume, Math.round(audio.volume * 100) + "%", audio.muted);
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.showVolume(); }
        function onMutedChanged() { root.showVolume(); }
    }

    Connections {
        target: root.source?.audio ?? null
        function onMutedChanged() {
            const muted = root.source.audio.muted;
            if (root.ready) root.show(muted ? "microphone-off" : "microphone", null, muted ? "Microphone off" : "Microphone on", muted);
        }
    }

    // Brightness

    Process {
        id: brightness
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            // device,class,current,percent,max
            onStreamFinished: {
                const percent = parseInt(text.split(",")[3]);
                if (!isNaN(percent)) root.show("sun", percent / 100, percent + "%", false);
            }
        }
    }

    IpcHandler {
        target: "osd"

        function brightness(): void { brightness.running = true; }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.surface
        border.width: 2

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.padding + 4
            anchors.rightMargin: Theme.padding + 4
            spacing: 12

            SvgIcon {
                name: root.icon
                size: Theme.iconSize + 2
                color: root.dim ? Theme.muted : Theme.fg
            }

            // Level bar, or the label when there is no level
            Item {
                Layout.fillWidth: true
                implicitHeight: 6
                visible: root.level !== null

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.surface
                }
                Rectangle {
                    height: parent.height
                    width: Math.min(1, root.level ?? 0) * parent.width
                    radius: height / 2
                    color: root.dim ? Theme.muted : Theme.accent
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
            }

            Text {
                Layout.fillWidth: root.level === null
                Layout.preferredWidth: root.level === null ? -1 : 36
                horizontalAlignment: root.level === null ? Text.AlignLeft : Text.AlignRight
                text: root.label
                color: root.dim ? Theme.muted : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
