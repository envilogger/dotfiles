import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

// Popup with the current time and date, a month calendar, and the year's progress.
PopupWindow {
    id: root

    // Tallest the panel may get before its contents scroll.
    property real maxHeight: 800

    // 0 = Sunday ... 6 = Saturday.
    readonly property int firstDayOfWeek: 1

    readonly property date now: clock.date
    // Month shown in the grid (any date within it).
    property date shownMonth: new Date()

    readonly property bool isCurrentMonth: shownMonth.getFullYear() === now.getFullYear()
        && shownMonth.getMonth() === now.getMonth()

    // 42 cells (6 weeks) starting at the week containing the 1st of the shown month.
    readonly property var days: {
        const first = new Date(shownMonth.getFullYear(), shownMonth.getMonth(), 1);
        const offset = (first.getDay() - firstDayOfWeek + 7) % 7;
        const result = [];
        for (let i = 0; i < 42; i++)
            result.push(new Date(first.getFullYear(), first.getMonth(), 1 - offset + i));
        return result;
    }

    readonly property int year: now.getFullYear()
    readonly property int daysInYear: (new Date(year + 1, 0, 1) - new Date(year, 0, 1)) / 86400000
    readonly property int dayOfYear: Math.round((new Date(year, now.getMonth(), now.getDate()) - new Date(year, 0, 1)) / 86400000) + 1
    readonly property real yearProgress: (now - new Date(year, 0, 1)) / (new Date(year + 1, 0, 1) - new Date(year, 0, 1))

    readonly property int margin: Theme.padding + 2

    function moveMonth(step) {
        shownMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + step, 1);
    }

    implicitWidth: 300
    implicitHeight: Math.min(maxHeight, content.implicitHeight + 2 * margin)
    color: "transparent"

    // Seconds while open; the bar has its own per-minute clock.
    SystemClock {
        id: clock
        enabled: root.visible
        precision: SystemClock.Seconds
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
            shownMonth = new Date();
        } else {
            grab.active = false;
        }
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Theme.overlay
    }

    component NavButton: Icon {
        id: nav
        signal clicked()
        color: navMouse.containsMouse ? Theme.accent : Theme.fg
        font.pixelSize: Theme.fontSize + 4

        MouseArea {
            id: navMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
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
        Keys.onLeftPressed: root.moveMonth(-1)
        Keys.onRightPressed: root.moveMonth(1)

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

                // Time and date
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    text: Qt.formatDateTime(root.now, "HH:mm:ss")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 32
                    font.bold: true
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(root.now, "dddd, d MMMM yyyy")
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }

                Separator {}

                // Month navigation
                RowLayout {
                    Layout.fillWidth: true

                    NavButton {
                        code: 0xf0141
                        onClicked: root.moveMonth(-1)
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDateTime(root.shownMonth, "MMMM yyyy")
                        color: monthMouse.containsMouse && !root.isCurrentMonth ? Theme.accent : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 1
                        font.bold: true

                        // Back to the current month.
                        MouseArea {
                            id: monthMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: root.isCurrentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: root.shownMonth = new Date()
                        }
                    }
                    NavButton {
                        code: 0xf0142
                        onClicked: root.moveMonth(1)
                    }
                }

                // Month grid
                GridLayout {
                    id: grid
                    Layout.fillWidth: true
                    columns: 7
                    rowSpacing: 2
                    columnSpacing: 2

                    Repeater {
                        model: 7
                        Text {
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1  // equal widths
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.locale().dayName((root.firstDayOfWeek + index) % 7, Locale.ShortFormat).slice(0, 2)
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.smallFontSize
                            font.bold: true
                        }
                    }

                    Repeater {
                        model: root.days

                        Rectangle {
                            id: day
                            required property date modelData
                            readonly property bool inMonth: modelData.getMonth() === root.shownMonth.getMonth()
                            readonly property bool isToday: modelData.toDateString() === root.now.toDateString()
                            readonly property bool weekend: modelData.getDay() === 0 || modelData.getDay() === 6

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 30
                            radius: 6
                            color: isToday ? Theme.accent : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: day.modelData.getDate()
                                color: day.isToday ? Theme.bg
                                    : !day.inMonth ? Theme.overlay
                                    : day.weekend ? Theme.crit
                                    : Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                font.bold: day.isToday
                            }
                        }
                    }

                    // Scroll to change month.
                    WheelHandler {
                        onWheel: e => root.moveMonth(e.angleDelta.y > 0 ? -1 : 1)
                    }
                }

                Separator {}

                // Year progress
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: `${root.year}`
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                    Text {
                        text: `${(root.yearProgress * 100).toFixed(1)}%`
                        color: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Theme.overlay

                    Rectangle {
                        width: parent.width * root.yearProgress
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }
                }
                Text {
                    Layout.bottomMargin: 2
                    text: `Day ${root.dayOfYear} of ${root.daysInYear} · ${root.daysInYear - root.dayOfYear} left`
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.smallFontSize
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
