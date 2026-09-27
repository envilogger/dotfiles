import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs

// Layout of Hyprland's main keyboard ("EN", "RU", …). Click: switch to the next layout.
Item {
    id: root

    property string layout: ""

    visible: layout !== ""
    // Even width, so ColumnLayout's rounded centring doesn't shift it by half a pixel.
    implicitWidth: Math.ceil(label.implicitWidth / 2) * 2
    implicitHeight: label.implicitHeight

    Process {
        id: query
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kb = JSON.parse(text).keyboards.find(k => k.main);
                    const code = kb.layout.split(",")[kb.active_layout_index] ?? "";
                    root.layout = code === "us" ? "EN" : code.toUpperCase();
                } catch (e) {
                    root.layout = "";
                }
            }
        }
    }

    // activelayout fires per keyboard; re-query to read the main one's state.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout" || event.name === "configreloaded")
                query.running = true;
        }
    }

    Text {
        id: label
        // Not anchors.centerIn: it rounds to whole pixels, which shows at this width.
        x: (root.width - implicitWidth) / 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.layout
        color: area.containsMouse ? Theme.accent : Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    MouseArea {
        id: area
        // Larger than the label: the full bar width, and half the gap to neighbouring widgets.
        anchors.fill: parent
        anchors.leftMargin: -(Theme.barWidth - root.width) / 2
        anchors.rightMargin: -(Theme.barWidth - root.width) / 2
        anchors.topMargin: -Theme.spacing / 2
        anchors.bottomMargin: -Theme.spacing / 2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "current", "next"])
    }
}
