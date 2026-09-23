import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs

// Popup with output/input device selection, their volumes, and per-app volumes.
PopupWindow {
    id: root

    // Tallest the panel may get before its contents scroll.
    property real maxHeight: 800

    readonly property var nodes: Pipewire.nodes.values
    readonly property list<PwNode> sinks: nodes.filter(n => n.audio && !n.isStream && n.isSink)
    readonly property list<PwNode> sources: nodes.filter(n => n.audio && !n.isStream && !n.isSink)
    readonly property list<PwNode> streams: nodes.filter(n => n.audio && n.type === PwNodeType.AudioOutStream)
    readonly property list<PwNode> inStreams: nodes.filter(n => n.audio && n.type === PwNodeType.AudioInStream)
    // Apps capturing audio, minus monitor captures (visualizers, level meters).
    readonly property list<PwNode> recording: inStreams.filter(n => n.properties["stream.monitor"] !== "true")

    // One row per app rather than per stream.
    readonly property var appGroups: groupByApp(streams)
    readonly property var recordingGroups: groupByApp(recording)

    readonly property int margin: Theme.padding + 2

    function groupByApp(nodes) {
        const groups = new Map();
        for (const n of nodes) {
            const p = n.properties;
            const key = p["application.process.binary"] || p["application.name"] || n.name;
            if (!groups.has(key)) groups.set(key, []);
            groups.get(key).push(n);
        }
        return [...groups.values()];
    }

    implicitWidth: 360
    implicitHeight: Math.min(maxHeight, content.implicitHeight + 2 * margin)
    color: "transparent"

    // Bind audio properties (volume/mute) of everything shown while open. Capture
    // streams are always tracked so the bar icon can show when the mic is in use.
    PwObjectTracker {
        objects: root.visible ? [...root.sinks, ...root.sources, ...root.streams, ...root.inStreams] : root.inStreams
    }

    // Close when clicking outside the panel. The grab is activated shortly after the
    // popup is shown: activating it before the popup surface is mapped leaves the popup
    // out of the grab, so the first click inside it would dismiss the panel.
    HyprlandFocusGrab {
        id: grab
        windows: [root]
        onCleared: root.visible = false
    }

    Timer {
        id: grabDelay
        interval: 100
        onTriggered: {
            grab.active = root.visible;
            if (root.visible) frame.forceActiveFocus();
        }
    }

    onVisibleChanged: {
        if (visible) {
            grabDelay.restart();
            flick.contentY = 0;
        } else {
            grab.active = false;
        }
    }

    component Header: RowLayout {
        property string icon
        property string title
        spacing: 8
        Layout.topMargin: 4

        SvgIcon {
            name: parent.icon
            color: Theme.accent
            size: Theme.fontSize + 4
        }
        Text {
            text: parent.title
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 1
            font.bold: true
        }
    }

    // Level meter lined up under a VolumeRow's slider (past its icon, before its percentage).
    component Level: LevelMeter {
        Layout.fillWidth: true
        Layout.leftMargin: 30
        Layout.rightMargin: 46
        Layout.topMargin: -4
        active: root.visible
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Theme.overlay
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.surface
        border.width: 2
        focus: true
        Keys.onEscapePressed: root.visible = false

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: root.margin
            contentHeight: content.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: content
                width: flick.width
                spacing: 8

                MediaPlayer {
                    id: media
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    active: root.visible
                }

                Separator { visible: media.visible }

                Header { icon: "device-speaker"; title: "Output" }
                VolumeRow {
                    Layout.fillWidth: true
                    node: Pipewire.defaultAudioSink
                }
                Level { node: Pipewire.defaultAudioSink }
                DeviceList {
                    Layout.fillWidth: true
                    devices: root.sinks
                    current: Pipewire.defaultAudioSink
                    onSelected: node => Pipewire.preferredDefaultAudioSink = node
                }

                Separator {}

                Header { icon: "microphone"; title: "Input" }
                VolumeRow {
                    Layout.fillWidth: true
                    node: Pipewire.defaultAudioSource
                    iconOn: "microphone"
                    iconOff: "microphone-off"
                }
                Level { node: Pipewire.defaultAudioSource }
                DeviceList {
                    Layout.fillWidth: true
                    devices: root.sources
                    current: Pipewire.defaultAudioSource
                    onSelected: node => Pipewire.preferredDefaultAudioSource = node
                }

                Separator {}

                Header { icon: "apps"; title: "Applications" }
                Text {
                    visible: root.streams.length === 0
                    text: "No apps are playing audio"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
                Repeater {
                    model: root.appGroups
                    StreamRow {
                        required property var modelData
                        Layout.fillWidth: true
                        nodes: modelData
                    }
                }

                Separator { visible: root.recording.length > 0 }

                Header {
                    visible: root.recording.length > 0
                    icon: "player-record"
                    title: "Recording"
                }
                Repeater {
                    model: root.recordingGroups
                    StreamRow {
                        required property var modelData
                        Layout.fillWidth: true
                        nodes: modelData
                        iconOn: "microphone"
                        iconOff: "microphone-off"
                    }
                }
            }
        }

        // Scroll indicator, only when the contents overflow.
        Rectangle {
            visible: flick.contentHeight > flick.height
            anchors.right: parent.right
            anchors.rightMargin: 4
            y: flick.y + flick.visibleArea.yPosition * flick.height
            width: 3
            height: flick.visibleArea.heightRatio * flick.height
            radius: 1.5
            color: Theme.overlay
        }
    }
}
