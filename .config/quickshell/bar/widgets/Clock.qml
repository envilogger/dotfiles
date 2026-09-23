import QtQuick
import Quickshell
import qs

Column {
    spacing: 2

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
        font.bold: true
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "dd.MM")
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: Theme.smallFontSize
    }
}
