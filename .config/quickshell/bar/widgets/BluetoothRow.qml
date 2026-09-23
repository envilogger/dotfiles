import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs

// One Bluetooth device. Click: disconnect if connected, otherwise connect (pairing
// first if needed). Paired devices show a star, and a trash button on hover to forget them.
Rectangle {
    id: root

    required property BluetoothDevice device

    readonly property bool busy: device.pairing
        || device.state === BluetoothDeviceState.Connecting
        || device.state === BluetoothDeviceState.Disconnecting
    // Connect once a pairing started from here completes.
    property bool connectAfterPair: false

    readonly property int iconCode: {
        const icon = device.icon;
        return icon.includes("headset") ? 0xf02ce
            : icon.includes("headphone") ? 0xf02cb
            : icon.startsWith("audio") ? 0xf04c3
            : icon.includes("mouse") ? 0xf037d
            : icon.includes("keyboard") ? 0xf030c
            : icon.includes("gaming") ? 0xf0296
            : icon.includes("phone") ? 0xf011c
            : icon.includes("computer") ? 0xf0322
            : icon.includes("display") || icon.includes("video") ? 0xf0379
            : 0xf00af;
    }

    implicitHeight: row.implicitHeight + 10
    radius: 6
    color: mouse.containsMouse ? Theme.overlay : "transparent"

    function activate() {
        if (busy) return;
        if (device.connected) {
            device.disconnect();
        } else if (device.paired) {
            device.connect();
        } else {
            connectAfterPair = true;
            device.pair();
        }
    }

    Connections {
        target: root.device
        function onPairedChanged() {
            if (!root.device.paired || !root.connectAfterPair) return;
            root.connectAfterPair = false;
            // Trusted devices may reconnect on their own later.
            root.device.trusted = true;
            root.device.connect();
        }
        function onPairingChanged() {
            if (!root.device.pairing && !root.device.paired) root.connectAfterPair = false;
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activate()
    }

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Icon {
            code: root.iconCode
            font.pixelSize: Theme.fontSize + 4
            color: root.device.connected ? Theme.accent : Theme.fg
            Layout.preferredWidth: 20
        }

        Text {
            Layout.fillWidth: true
            text: root.device.name || root.device.address
            elide: Text.ElideRight
            color: root.device.connected || root.device.paired ? Theme.fg : Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: root.device.connected
        }

        Text {
            visible: root.busy
            text: root.device.pairing ? "Pairing…"
                : root.device.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                : "Connecting…"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.smallFontSize
        }

        Text {
            visible: root.device.connected && root.device.batteryAvailable
            text: `${Math.round(root.device.battery * 100)}%`
            color: root.device.battery < 0.2 ? Theme.crit : Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.smallFontSize
        }

        // Forget (unpair), shown on hover.
        Icon {
            visible: root.device.paired && mouse.containsMouse || forgetMouse.containsMouse
            code: 0xf0a7a
            font.pixelSize: Theme.fontSize + 2
            color: forgetMouse.containsMouse ? Theme.crit : Theme.muted

            MouseArea {
                id: forgetMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.device.forget()
            }
        }

        // Paired
        Icon {
            visible: root.device.paired && !root.device.connected
            code: 0xf04ce
            font.pixelSize: Theme.fontSize + 2
            color: Theme.muted
        }
    }
}
