import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs

// Popup with output/input device selection, their volumes, and per-app volumes.
PopupWindow {
    id: root

    readonly property var nodes: Pipewire.nodes.values
    readonly property list<PwNode> sinks: nodes.filter(n => n.audio && !n.isStream && n.isSink)
    readonly property list<PwNode> sources: nodes.filter(n => n.audio && !n.isStream && !n.isSink)
    readonly property list<PwNode> streams: nodes.filter(n => n.audio && n.type === PwNodeType.AudioOutStream)

    implicitWidth: 340
    implicitHeight: content.implicitHeight + 2 * Theme.padding + 4
    color: "transparent"

    // Bind audio properties (volume/mute) of everything shown while open.
    PwObjectTracker {
        objects: root.visible ? [...root.sinks, ...root.sources, ...root.streams] : []
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
        onTriggered: grab.active = root.visible
    }

    onVisibleChanged: {
        if (visible) grabDelay.restart();
        else grab.active = false;
    }

    component Header: RowLayout {
        property int code
        property string title
        spacing: 8
        Layout.topMargin: 4

        Icon {
            code: parent.code
            color: Theme.accent
            font.pixelSize: Theme.fontSize + 4
        }
        Text {
            text: parent.title
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 1
            font.bold: true
        }
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Theme.overlay
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.surface
        border.width: 2
        focus: true
        Keys.onEscapePressed: root.visible = false

        ColumnLayout {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Theme.padding + 2
            }
            spacing: 8

            Header { code: 0xf04c3; title: "Output" }
            VolumeRow {
                Layout.fillWidth: true
                node: Pipewire.defaultAudioSink
            }
            DeviceList {
                Layout.fillWidth: true
                devices: root.sinks
                current: Pipewire.defaultAudioSink
                onSelected: node => Pipewire.preferredDefaultAudioSink = node
            }

            Separator {}

            Header { code: 0xf036c; title: "Input" }
            VolumeRow {
                Layout.fillWidth: true
                node: Pipewire.defaultAudioSource
                iconOn: 0xf036c
                iconOff: 0xf036d
            }
            DeviceList {
                Layout.fillWidth: true
                devices: root.sources
                current: Pipewire.defaultAudioSource
                onSelected: node => Pipewire.preferredDefaultAudioSource = node
            }

            Separator {}

            Header { code: 0xf003b; title: "Applications" }
            Text {
                visible: root.streams.length === 0
                text: "No apps are playing audio"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
            Repeater {
                model: root.streams

                ColumnLayout {
                    id: stream
                    required property PwNode modelData
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: {
                            const p = stream.modelData.properties;
                            const app = p["application.name"] || stream.modelData.description || stream.modelData.name;
                            const media = p["media.name"];
                            return media && media !== app ? app + " — " + media : app;
                        }
                        elide: Text.ElideRight
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.smallFontSize + 1
                    }
                    VolumeRow {
                        Layout.fillWidth: true
                        node: stream.modelData
                    }
                }
            }
        }
    }
}
