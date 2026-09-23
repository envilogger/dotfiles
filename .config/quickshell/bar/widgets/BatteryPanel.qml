import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import qs

// Popup with battery status, a 24-hour charge chart, and battery details.
PopupWindow {
    id: root

    // Tallest the panel may get before its contents scroll.
    property real maxHeight: 800
    // Live values come from the display device; history and details from the battery.
    property UPowerDevice dev
    readonly property UPowerDevice battery: UPower.devices.values.find(d => d.isLaptopBattery) ?? null

    readonly property real level: dev?.percentage ?? 0
    readonly property int batState: dev?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: batState === UPowerDeviceState.Charging
    readonly property bool discharging: batState === UPowerDeviceState.Discharging

    // Filled in by `details` from UPower over D-Bus: not all of it is exposed by Quickshell.
    // [{ t: unix seconds, v: percent }], oldest first. UPower records a point only when
    // the charge changes, so each value holds until the next one.
    property var history: []
    property var props: ({})
    readonly property real historySpan: 24 * 3600
    // Moves the chart's time window along while open.
    readonly property real now: clock.date.getTime() / 1000

    SystemClock {
        id: clock
        enabled: root.visible
        precision: SystemClock.Minutes
    }

    readonly property int margin: Theme.padding + 2

    function formatDuration(seconds) {
        const m = Math.round(seconds / 60);
        if (m < 60) return `${m} min`;
        const h = Math.floor(m / 60);
        return m % 60 ? `${h} h ${m % 60} min` : `${h} h`;
    }

    readonly property string statusText: {
        switch (batState) {
        case UPowerDeviceState.Charging:
            return (dev?.timeToFull ?? 0) > 0 ? `Charging · ${formatDuration(dev.timeToFull)} until full` : "Charging";
        case UPowerDeviceState.Discharging:
            return (dev?.timeToEmpty ?? 0) > 0 ? `On battery · ${formatDuration(dev.timeToEmpty)} left` : "On battery";
        case UPowerDeviceState.FullyCharged:
            return "Fully charged";
        case UPowerDeviceState.PendingCharge:
            return "Plugged in, not charging";
        default:
            return UPowerDeviceState.toString(batState);
        }
    }

    readonly property string batteryPath: battery
        ? `/org/freedesktop/UPower/devices/battery_${battery.nativePath}` : ""

    // Charge limit: on this laptop, Lenovo's conservation mode (stops around 80%).
    readonly property bool limitSupported: props.ChargeThresholdSupported ?? false
    readonly property bool limitEnabled: props.ChargeThresholdEnabled ?? false
    property string limitError: ""

    function setChargeLimit(enable) {
        if (!batteryPath || chargeLimit.running) return;
        limitError = "";
        chargeLimit.exec(["busctl", "call", "org.freedesktop.UPower", batteryPath,
            "org.freedesktop.UPower.Device", "EnableChargeThreshold", "b", enable ? "true" : "false"]);
    }

    function refresh() {
        if (!batteryPath || details.running) return;
        const path = batteryPath;
        details.exec(["sh", "-c", `
            busctl --json=short call org.freedesktop.UPower "$1" org.freedesktop.UPower.Device GetHistory suu charge ${historySpan} 200
            echo
            busctl --json=short call org.freedesktop.UPower "$1" org.freedesktop.DBus.Properties GetAll s org.freedesktop.UPower.Device
        `, "sh", path]);
    }

    function parseDetails(text) {
        const [historyJson, propsJson] = text.split("\n").filter(l => l.trim());
        try {
            // Newest first; entries are [time, percent, state]. Entries with state 0
            // (unknown) and 0% are restart markers, not readings.
            history = JSON.parse(historyJson).data[0]
                .filter(([t, v, state]) => state !== 0)
                .map(([t, v]) => ({ t, v }))
                .reverse();
            const all = JSON.parse(propsJson).data[0];
            const p = {};
            for (const key in all) p[key] = all[key].data;
            props = p;
        } catch (e) {
            console.warn("Battery: can't read UPower details:", e);
        }
    }

    implicitWidth: 340
    implicitHeight: Math.min(maxHeight, content.implicitHeight + 2 * margin)
    color: "transparent"

    Process {
        id: chargeLimit
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.limitError = text.trim().split("\n").pop()
        }
        onExited: code => {
            if (code !== 0 && !root.limitError) root.limitError = "Failed to change the charge limit";
            root.refresh();
        }
    }

    Process {
        id: details
        stdout: StdioCollector {
            onStreamFinished: root.parseDetails(text)
        }
    }

    Timer {
        running: root.visible
        interval: 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
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

    component Label: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    component Value: Text {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    component AxisLabel: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: Theme.smallFontSize
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

                // Level and status
                Text {
                    Layout.topMargin: 4
                    text: `${Math.round(root.level * 100)}%`
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 32
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: root.statusText
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }

                Separator {}

                // Charge over the last 24 hours
                Header { code: 0xf012a; title: "Last 24 hours" }

                Item {
                    id: chartBox
                    Layout.fillWidth: true
                    implicitHeight: 110

                    readonly property int axisWidth: 34
                    readonly property int axisHeight: 16
                    readonly property real plotWidth: width - axisWidth
                    readonly property real plotHeight: height - axisHeight
                    readonly property real start: root.now - root.historySpan

                    // Points in the window, starting with the value current at its start,
                    // and ending with the current level at "now".
                    readonly property var points: {
                        const before = root.history.filter(p => p.t < start);
                        const inside = root.history.filter(p => p.t >= start && p.t < root.now);
                        const first = before.length ? [{ t: start, v: before[before.length - 1].v }] : [];
                        return first.concat(inside, [{ t: root.now, v: root.level * 100 }]);
                    }

                    function xFor(t) { return Math.max(0, (t - start) / root.historySpan) * plotWidth; }
                    function yFor(v) { return (1 - v / 100) * plotHeight; }

                    // Hovered point, or null.
                    property var hovered: null

                    // Y axis labels
                    Repeater {
                        model: [100, 50, 0]
                        AxisLabel {
                            required property int modelData
                            x: chartBox.plotWidth + 6
                            y: chartBox.yFor(modelData) - height / 2
                            text: `${modelData}%`
                        }
                    }

                    // X axis labels
                    AxisLabel { x: 0; y: chartBox.plotHeight + 3; text: "24h ago" }
                    AxisLabel {
                        x: chartBox.plotWidth / 2 - width / 2
                        y: chartBox.plotHeight + 3
                        text: "12h"
                    }
                    AxisLabel {
                        x: chartBox.plotWidth - width
                        y: chartBox.plotHeight + 3
                        text: "now"
                    }

                    Canvas {
                        id: chart
                        width: chartBox.plotWidth
                        height: chartBox.plotHeight

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();

                            // Recessive gridlines at 0, 50 and 100%.
                            ctx.strokeStyle = Theme.surface;
                            ctx.lineWidth = 1;
                            for (const v of [0, 50, 100]) {
                                const y = Math.round(chartBox.yFor(v)) + 0.5;
                                ctx.beginPath();
                                ctx.moveTo(0, Math.min(y, height - 0.5));
                                ctx.lineTo(width, Math.min(y, height - 0.5));
                                ctx.stroke();
                            }
                            const pts = chartBox.points;
                            if (pts.length >= 2) {
                                // Step path: each value holds until the next reading.
                                const trace = (start) => {
                                    pts.forEach((p, i) => {
                                        const x = chartBox.xFor(p.t), y = chartBox.yFor(p.v);
                                        if (i === 0) start(x, y);
                                        else {
                                            ctx.lineTo(x, chartBox.yFor(pts[i - 1].v));
                                            ctx.lineTo(x, y);
                                        }
                                    });
                                };

                                // Area under the line
                                ctx.beginPath();
                                ctx.moveTo(chartBox.xFor(pts[0].t), height);
                                trace((x, y) => ctx.lineTo(x, y));
                                ctx.lineTo(chartBox.xFor(pts[pts.length - 1].t), height);
                                ctx.closePath();
                                ctx.fillStyle = Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15);
                                ctx.fill();

                                // Line
                                ctx.beginPath();
                                trace((x, y) => ctx.moveTo(x, y));
                                ctx.strokeStyle = Theme.accent;
                                ctx.lineWidth = 2;
                                ctx.lineJoin = "round";
                                ctx.lineCap = "round";
                                ctx.stroke();
                            }

                            // Hover crosshair and point
                            const h = chartBox.hovered;
                            if (h) {
                                const x = chartBox.xFor(h.t), y = chartBox.yFor(h.v);
                                ctx.strokeStyle = Theme.muted;
                                ctx.lineWidth = 1;
                                ctx.beginPath();
                                ctx.moveTo(Math.round(x) + 0.5, 0);
                                ctx.lineTo(Math.round(x) + 0.5, height);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.arc(x, y, 4, 0, 2 * Math.PI);
                                ctx.fillStyle = Theme.accent;
                                ctx.fill();
                                ctx.lineWidth = 2;
                                ctx.strokeStyle = Theme.bg;
                                ctx.stroke();
                            }
                        }

                        Connections {
                            target: chartBox
                            function onPointsChanged() { chart.requestPaint(); }
                            function onHoveredChanged() { chart.requestPaint(); }
                            function onWidthChanged() { chart.requestPaint(); }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onPositionChanged: mouse => {
                                let best = null;
                                for (const p of chartBox.points) {
                                    if (!best || Math.abs(chartBox.xFor(p.t) - mouse.x) < Math.abs(chartBox.xFor(best.t) - mouse.x))
                                        best = p;
                                }
                                chartBox.hovered = best;
                            }
                            onExited: chartBox.hovered = null
                        }
                    }

                    // Tooltip
                    Rectangle {
                        visible: chartBox.hovered !== null
                        readonly property real px: chartBox.hovered ? chartBox.xFor(chartBox.hovered.t) : 0
                        x: Math.max(0, Math.min(chartBox.plotWidth - width, px - width / 2))
                        y: 0
                        width: tip.implicitWidth + 12
                        height: tip.implicitHeight + 6
                        radius: 4
                        color: Theme.surface

                        Text {
                            id: tip
                            anchors.centerIn: parent
                            text: chartBox.hovered
                                ? `${Qt.formatDateTime(new Date(chartBox.hovered.t * 1000), "HH:mm")} · ${Math.round(chartBox.hovered.v)}%`
                                : ""
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.smallFontSize
                        }
                    }
                }

                Separator {}

                // Details
                Header { code: 0xf0079; title: "Battery" }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 4
                    columnSpacing: 12

                    Label { text: root.charging ? "Charging at" : root.discharging ? "Drawing" : "Power" }
                    Value { text: `${(root.dev?.changeRate ?? 0).toFixed(1)} W` }

                    Label { text: "Energy" }
                    Value { text: `${(root.dev?.energy ?? 0).toFixed(1)} / ${(root.dev?.energyCapacity ?? 0).toFixed(1)} Wh` }

                    Label { text: "Health" }
                    Value {
                        text: root.props.EnergyFullDesign
                            ? `${Math.round(root.props.Capacity)}% of ${root.props.EnergyFullDesign.toFixed(0)} Wh`
                            : "—"
                    }

                    Label { text: "Charge cycles" }
                    Value { text: root.props.ChargeCycles > 0 ? root.props.ChargeCycles : "—" }

                    Label { text: "Voltage" }
                    Value { text: root.props.Voltage ? `${root.props.Voltage.toFixed(2)} V` : "—" }

                    Label { text: "Model" }
                    Value { text: [root.props.Vendor, root.props.Model].filter(s => s).join(" ") || "—" }
                }

                Separator { visible: root.limitSupported }

                // Charge limit
                RowLayout {
                    visible: root.limitSupported
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Limit charge to 80%"
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Slows battery wear when mostly plugged in"
                            wrapMode: Text.Wrap
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.smallFontSize
                        }
                    }

                    // Switch
                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 20
                        radius: 10
                        color: root.limitEnabled ? Theme.accent : Theme.overlay
                        opacity: chargeLimit.running ? 0.5 : 1

                        Rectangle {
                            x: root.limitEnabled ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            radius: 7
                            color: root.limitEnabled ? Theme.bg : Theme.fg
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setChargeLimit(!root.limitEnabled)
                        }
                    }
                }
                Text {
                    visible: root.limitError !== ""
                    Layout.fillWidth: true
                    text: root.limitError
                    wrapMode: Text.Wrap
                    color: Theme.crit
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
