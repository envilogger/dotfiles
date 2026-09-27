import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Shown while wf-recorder runs (~/.local/bin/screencast): a blinking dot over the
// elapsed time. Click: stop the recording.
Item {
    id: root

    // Seconds since wf-recorder started, or -1 when it isn't running
    property int elapsed: -1
    readonly property bool recording: elapsed >= 0

    visible: recording
    implicitWidth: Math.max(dot.width, time.implicitWidth)
    implicitHeight: dot.height + time.implicitHeight

    Process {
        id: poll
        command: ["ps", "-o", "etimes=", "-C", "wf-recorder"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seconds = parseInt(text.trim().split("\n")[0]);
                root.elapsed = isNaN(seconds) ? -1 : seconds;
            }
        }
    }

    Timer {
        running: true
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    SvgIcon {
        id: dot
        anchors.horizontalCenter: parent.horizontalCenter
        name: "player-record-filled"
        color: area.containsMouse ? Theme.accent : Theme.crit

        SequentialAnimation on opacity {
            running: root.recording
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutQuad }
        }
    }

    Text {
        id: time
        anchors.top: dot.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.floor(root.elapsed / 60) + ":" + String(root.elapsed % 60).padStart(2, "0")
        color: area.containsMouse ? Theme.accent : Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.smallFontSize
    }

    Process {
        id: stop
        command: ["pkill", "-INT", "-x", "wf-recorder"]
    }

    MouseArea {
        id: area
        // Larger than the icon: the full bar width, and half the gap to neighbouring widgets.
        anchors.fill: parent
        anchors.leftMargin: -(Theme.barWidth - root.width) / 2
        anchors.rightMargin: -(Theme.barWidth - root.width) / 2
        anchors.topMargin: -Theme.spacing / 2
        anchors.bottomMargin: -Theme.spacing / 2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: stop.running = true
    }
}
