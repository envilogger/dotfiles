import QtQuick
import Quickshell
import qs

Icon {
    code: 0xf303
    color: mouse.containsMouse ? Qt.lighter(Theme.accent, 1.25) : Theme.accent
    font.pixelSize: 26

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["hyprlauncher"])
    }
}
