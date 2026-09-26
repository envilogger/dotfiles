import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

// Popup with plan limits and tokens per day for the last week, with a tab each for
// Claude and ChatGPT (Codex). Data comes from AiUsageData.
PopupWindow {
    id: root

    // Tallest the panel may get before its contents scroll.
    property real maxHeight: 800
    property string tab: "claude"
    readonly property var usage: AiUsageData.usage
    readonly property var current: usage?.[tab] ?? null
    readonly property var days: current?.days ?? []
    readonly property real maxTokens: Math.max(1, ...days.map(d => d.tokens))
    // Keeps the reset countdowns current while open.
    readonly property real now: clock.date.getTime()

    readonly property int margin: Theme.padding + 2

    SystemClock {
        id: clock
        enabled: root.visible
        precision: SystemClock.Minutes
    }

    function formatTokens(n) {
        if (n >= 1e6) return `${(n / 1e6).toFixed(1)}M`;
        if (n >= 1e3) return `${(n / 1e3).toFixed(1)}K`;
        return `${n}`;
    }

    function formatReset(iso) {
        if (!iso) return "";
        const at = new Date(iso);
        const m = Math.max(0, Math.round((at.getTime() - now) / 60000));
        if (m < 60) return `Resets in ${m} min`;
        if (m < 24 * 60) return `Resets in ${Math.floor(m / 60)} h ${m % 60} min`;
        return `Resets ${Qt.formatDateTime(at, "ddd HH:mm")}`;
    }

    function levelColor(percent) {
        return percent >= 90 ? Theme.crit : percent >= 70 ? Theme.warn : Theme.accent;
    }

    implicitWidth: 340
    implicitHeight: Math.min(maxHeight, content.implicitHeight + 2 * margin)
    color: "transparent"

    // Refresh more often while open than the background refresh does.
    Timer {
        running: root.visible
        interval: 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: AiUsageData.refresh()
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

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Theme.overlay
    }

    component Meter: Rectangle {
        property real fraction
        property color fill: Theme.accent
        Layout.fillWidth: true
        implicitHeight: 6
        radius: 3
        color: Theme.surface

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, parent.fraction))
            height: parent.height
            radius: parent.radius
            color: parent.fill
        }
    }

    component TabButton: Rectangle {
        id: tabButton
        property string key
        property string icon
        property string title
        readonly property bool active: root.tab === key

        Layout.fillWidth: true
        implicitHeight: 28
        radius: Theme.radius - 4
        color: active ? Theme.surface : tabArea.containsMouse ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.5) : "transparent"

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            SvgIcon {
                name: tabButton.icon
                color: tabButton.active ? Theme.accent : Theme.muted
                size: Theme.fontSize + 2
            }
            Text {
                text: tabButton.title
                color: tabButton.active ? Theme.fg : Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.bold: tabButton.active
            }
        }

        MouseArea {
            id: tabArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.tab = tabButton.key
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

                Header { icon: "settings-ai"; title: "AI usage" }

                // Tabs
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: tabs.implicitHeight + 6
                    radius: Theme.radius - 2
                    border.color: Theme.surface
                    border.width: 1
                    color: "transparent"

                    RowLayout {
                        id: tabs
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3

                        TabButton { key: "claude"; icon: "sparkles"; title: "Claude" }
                        TabButton { key: "chatgpt"; icon: "brand-openai"; title: "ChatGPT" }
                    }
                }

                Text {
                    visible: root.usage === null
                    text: "Loading…"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    visible: !!root.current?.error
                    Layout.fillWidth: true
                    text: root.current?.error ?? ""
                    wrapMode: Text.Wrap
                    color: Theme.warn
                    font.family: Theme.font
                    font.pixelSize: Theme.smallFontSize
                }

                // Limits: session, week, and per-model weekly limits
                Repeater {
                    model: root.current?.limits ?? []

                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                            }
                            Text {
                                text: `${Math.round(modelData.percent)}%`
                                color: root.levelColor(modelData.percent)
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                            }
                        }
                        Meter {
                            fraction: modelData.percent / 100
                            fill: root.levelColor(modelData.percent)
                        }
                        Text {
                            visible: text !== ""
                            text: root.formatReset(modelData.resetsAt)
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.smallFontSize
                        }
                    }
                }

                Separator { visible: root.days.length > 0 }

                // Tokens per day; the busiest day of the week fills the bar.
                Header {
                    visible: root.days.length > 0
                    icon: "chart-bar"
                    title: "Last 7 days"
                }
                Repeater {
                    model: root.days.slice().reverse()

                    RowLayout {
                        id: dayRow
                        required property var modelData
                        required property int index
                        readonly property date date: new Date(`${modelData.date}T00:00`)
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            Layout.preferredWidth: 58
                            text: dayRow.index === 0 ? "Today" : Qt.formatDate(dayRow.date, "ddd d")
                            color: dayRow.index === 0 ? Theme.fg : Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                        Meter {
                            fraction: dayRow.modelData.tokens / root.maxTokens
                        }
                        Text {
                            Layout.preferredWidth: 48
                            horizontalAlignment: Text.AlignRight
                            text: root.formatTokens(dayRow.modelData.tokens)
                            color: dayRow.modelData.tokens ? Theme.fg : Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                    }
                }

                Text {
                    visible: root.usage !== null
                    Layout.topMargin: 4
                    text: `Updated ${Qt.formatDateTime(new Date(root.usage?.updated ?? 0), "HH:mm")}`
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
