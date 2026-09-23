import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs

// Selectable list of audio devices; the current one is marked.
ColumnLayout {
    id: root

    property list<PwNode> devices
    property PwNode current
    signal selected(PwNode node)

    spacing: 2

    Repeater {
        model: root.devices

        Rectangle {
            id: item
            required property PwNode modelData
            readonly property bool active: modelData === root.current

            Layout.fillWidth: true
            implicitHeight: label.implicitHeight + 10
            radius: 6
            color: mouse.containsMouse ? Theme.overlay : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                SvgIcon {
                    name: "check"
                    size: Theme.fontSize + 2
                    color: Theme.accent
                    opacity: item.active ? 1 : 0
                    Layout.preferredWidth: 16
                }

                Text {
                    id: label
                    Layout.fillWidth: true
                    text: item.modelData.description || item.modelData.nickname || item.modelData.name
                    elide: Text.ElideRight
                    color: item.active ? Theme.fg : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(item.modelData)
            }
        }
    }
}
