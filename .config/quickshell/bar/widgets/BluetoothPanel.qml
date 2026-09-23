import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import qs

// Popup with the adapter's power switch, connected devices, and devices available to
// connect (paired ones first). Scans for devices while open.
PopupWindow {
    id: root

    // Tallest the panel may get before its contents scroll.
    property real maxHeight: 800
    property BluetoothAdapter adapter

    readonly property bool powered: adapter?.enabled ?? false
    readonly property var devices: adapter?.devices.values ?? []

    readonly property var connected: devices.filter(d => d.connected)
        .sort((a, b) => a.name.localeCompare(b.name))
    // Devices heard during the current scan, i.e. in range. Paired devices stay known to
    // BlueZ when they're away, so only list those that are nearby. Devices without a
    // name (just an address) are mostly beacons you can't connect to; hide them.
    // Paired first, then by name.
    property var nearby: new Set()
    readonly property var available: devices
        .filter(d => !d.connected && nearby.has(d.address) && (d.paired || d.deviceName !== ""))
        .sort((a, b) => (b.paired - a.paired) || a.name.localeCompare(b.name))

    // Quickshell doesn't expose signal strength; BlueZ sets RSSI only on devices it
    // currently hears, so read it from BlueZ's object tree.
    Process {
        id: rssi
        command: ["busctl", "--json=short", "call", "org.bluez", "/",
            "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const objects = JSON.parse(text).data[0];
                    const found = new Set();
                    for (const path in objects) {
                        const dev = objects[path]["org.bluez.Device1"];
                        if (dev?.RSSI) found.add(dev.Address.data);
                    }
                    root.nearby = found;
                } catch (e) {
                    console.warn("Bluetooth: can't read RSSI:", e);
                }
            }
        }
    }

    Timer {
        running: root.visible && root.powered
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!rssi.running) rssi.running = true
    }

    readonly property int margin: Theme.padding + 2

    implicitWidth: 340
    implicitHeight: Math.min(maxHeight, content.implicitHeight + 2 * margin)
    color: "transparent"

    // Scan while open (and powered). BlueZ rejects stopping a scan that is still
    // starting, and the property can briefly read false before the scan reports as
    // running, so stopping is re-checked for a few seconds. Scans started by others
    // are left alone.
    readonly property bool wantScan: visible && powered
    property bool ownsScan: false
    property int idleChecks: 0

    onWantScanChanged: {
        if (!adapter) return;
        if (wantScan) {
            ownsScan = true;
            adapter.discovering = true;
        } else if (ownsScan) {
            idleChecks = 0;
            adapter.discovering = false;
        }
    }

    Timer {
        running: root.ownsScan && !root.wantScan
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.adapter?.discovering) {
                root.idleChecks = 0;
                root.adapter.discovering = false;
            } else if (++root.idleChecks >= 5) {
                root.ownsScan = false;
            }
        }
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
            nearby = new Set();
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

    component Placeholder: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
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

                // Adapter name + power switch
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 12

                    SvgIcon {
                        name: root.powered ? "bluetooth" : "bluetooth-off"
                        color: root.powered ? Theme.accent : Theme.muted
                        size: Theme.iconSize + 6
                        Layout.preferredWidth: 28
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Bluetooth"
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 1
                            font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: !root.adapter ? "No adapter"
                                : !root.powered ? "Off"
                                : root.adapter.discovering ? "Scanning…"
                                : root.adapter.name
                            elide: Text.ElideRight
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    // Power switch
                    Rectangle {
                        visible: root.adapter !== null
                        implicitWidth: 36
                        implicitHeight: 20
                        radius: 10
                        color: root.powered ? Theme.accent : Theme.overlay

                        Rectangle {
                            x: root.powered ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            radius: 7
                            color: root.powered ? Theme.bg : Theme.fg
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.adapter.enabled = !root.adapter.enabled
                        }
                    }
                }

                Separator {}

                // Connected devices
                Header { icon: "bluetooth-connected"; title: "Connected" }
                Placeholder {
                    visible: root.connected.length === 0
                    text: "No devices connected"
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Repeater {
                        model: ScriptModel { values: root.connected }
                        BluetoothRow {
                            required property var modelData
                            Layout.fillWidth: true
                            device: modelData
                        }
                    }
                }

                Separator {}

                // Available devices
                Header { icon: "bluetooth"; title: "Available" }
                Placeholder {
                    visible: root.available.length === 0
                    text: !root.powered ? "Bluetooth is off" : "Scanning…"
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Repeater {
                        // ScriptModel keeps rows (and their pairing state) across re-sorts.
                        model: ScriptModel { values: root.available }
                        BluetoothRow {
                            required property var modelData
                            Layout.fillWidth: true
                            device: modelData
                        }
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
