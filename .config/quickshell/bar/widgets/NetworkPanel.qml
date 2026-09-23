import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import qs

// Popup with the active connection, DNS server selection, and available Wi-Fi networks.
PopupWindow {
    id: root

    // Tallest the panel may get before its contents scroll.
    property real maxHeight: 800

    // Active device (wired preferred), the Wi-Fi device (connected or not), and the
    // connected Wi-Fi network.
    property var device
    property var wifiDevice
    property var wifiNet
    property string iconName

    readonly property bool isWired: device?.type === DeviceType.Wired

    // Visible networks: connected first, then saved ones, then by signal strength.
    readonly property var networks: (wifiDevice?.networks.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected)
            || (b.known - a.known)
            || (b.signalStrength - a.signalStrength))

    // DNS presets; an empty server list means "use what DHCP hands out".
    readonly property var dnsPresets: [
        { name: "DHCP", servers: [] },
        { name: "Yandex", servers: ["77.88.8.8", "77.88.8.1"] },
        { name: "Quad9", servers: ["9.9.9.9", "149.112.112.112"] },
        { name: "Cloudflare", servers: ["1.1.1.1", "1.0.0.1"] },
    ]

    // Filled in by `info` from nmcli: the Quickshell API doesn't expose IP or DNS config.
    property string connUuid: ""
    property list<string> addresses: []
    property string dnsPreset: ""   // matching preset name, "" if custom/unknown
    property string pendingDns: ""  // preset being applied
    property string dnsError: ""

    property string expandedNetwork: ""

    readonly property int margin: Theme.padding + 2

    implicitWidth: 360
    implicitHeight: Math.min(maxHeight, content.implicitHeight + 2 * margin)
    color: "transparent"

    function refresh() {
        if (!device) {
            connUuid = "";
            addresses = [];
            dnsPreset = "";
            return;
        }
        info.exec(["sh", "-c", `
            uuid=$(nmcli -g GENERAL.CON-UUID device show "$1")
            echo "ip=$(nmcli -g IP4.ADDRESS device show "$1")"
            [ -n "$uuid" ] || exit 0
            echo "uuid=$uuid"
            echo "dns=$(nmcli -g ipv4.dns connection show uuid "$uuid")"
            echo "ignore=$(nmcli -g ipv4.ignore-auto-dns connection show uuid "$uuid")"
        `, "sh", device.name]);
    }

    function parseInfo(text) {
        const kv = {};
        for (const line of text.split("\n")) {
            const i = line.indexOf("=");
            if (i > 0) kv[line.slice(0, i)] = line.slice(i + 1).trim();
        }
        connUuid = kv.uuid ?? "";
        addresses = (kv.ip ?? "").split("|").map(s => s.trim().replace(/\/\d+$/, "")).filter(s => s);

        const servers = (kv.dns ?? "").split(",").map(s => s.trim()).filter(s => s).join(",");
        const ignoreAuto = kv.ignore === "yes";
        const preset = dnsPresets.find(p => p.servers.length === 0
            ? servers === "" && !ignoreAuto
            : ignoreAuto && p.servers.join(",") === servers);
        dnsPreset = preset?.name ?? "";
    }

    function setDns(preset) {
        if (!connUuid || dnsApply.running) return;
        dnsError = "";
        pendingDns = preset.name;
        const auto = preset.servers.length === 0;
        // Also ignore DHCPv6/RA-provided DNS so it can't bypass the chosen servers.
        dnsApply.exec(["sh", "-c", `
            nmcli connection modify uuid "$1" \
                ipv4.dns "$2" ipv4.ignore-auto-dns "$3" ipv6.ignore-auto-dns "$3" \
            && nmcli device reapply "$4"
        `, "sh", connUuid, preset.servers.join(","), auto ? "no" : "yes", device.name]);
    }

    // Refresh when the active connection changes while the panel is open.
    readonly property string connKey: `${device?.name}|${device?.state}|${wifiNet?.name}`
    onConnKeyChanged: if (visible) refreshDelay.restart()

    // Debounce: connection changes arrive as a burst of state updates.
    Timer {
        id: refreshDelay
        interval: 300
        onTriggered: root.refresh()
    }

    Process {
        id: info
        stdout: StdioCollector {
            onStreamFinished: root.parseInfo(text)
        }
    }

    Process {
        id: dnsApply
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.dnsError = text.trim().split("\n").pop()
        }
        onExited: code => {
            if (code !== 0 && !root.dnsError) root.dnsError = "Failed to apply DNS";
            root.pendingDns = "";
            root.refresh();
        }
    }

    // Scan for networks only while the panel is open.
    Binding {
        when: root.wifiDevice !== null
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.visible
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
            dnsError = "";
            refresh();
        } else {
            grab.active = false;
            expandedNetwork = "";
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

                // Active connection
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 12

                    SvgIcon {
                        name: root.iconName
                        color: root.device ? Theme.accent : Theme.muted
                        size: Theme.iconSize + 6
                        Layout.preferredWidth: 28
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: !root.device ? "Disconnected"
                                : root.isWired ? `Wired (${root.device.name})`
                                : root.wifiNet?.name ?? root.device.name
                            elide: Text.ElideRight
                            color: root.device ? Theme.fg : Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 1
                            font.bold: true
                        }
                        Text {
                            visible: root.device !== null
                            Layout.fillWidth: true
                            text: root.addresses.length > 0 ? root.addresses.join(", ") : "No IPv4 address"
                            elide: Text.ElideRight
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                    }
                }

                Separator {}

                // DNS
                Header { icon: "server"; title: "DNS" }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    enabled: root.connUuid !== "" && !dnsApply.running
                    opacity: root.connUuid !== "" ? 1 : 0.5

                    Repeater {
                        model: root.dnsPresets

                        Rectangle {
                            id: dnsButton
                            required property var modelData
                            readonly property bool active: root.dnsPreset === modelData.name
                            readonly property bool pending: root.pendingDns === modelData.name

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1  // equal widths
                            implicitHeight: dnsLabel.implicitHeight + 12
                            radius: 6
                            color: active ? Theme.accent
                                : dnsMouse.containsMouse ? Theme.overlay
                                : Theme.surface
                            border.color: pending ? Theme.accent : "transparent"
                            border.width: 1

                            Text {
                                id: dnsLabel
                                anchors.centerIn: parent
                                text: dnsButton.modelData.name
                                color: dnsButton.active ? Theme.bg : Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                font.bold: dnsButton.active
                            }

                            MouseArea {
                                id: dnsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (!dnsButton.active) root.setDns(dnsButton.modelData)
                            }
                        }
                    }
                }
                Text {
                    visible: root.dnsError !== ""
                    Layout.fillWidth: true
                    text: root.dnsError
                    wrapMode: Text.Wrap
                    color: Theme.crit
                    font.family: Theme.font
                    font.pixelSize: Theme.smallFontSize
                }

                Separator {}

                // Wi-Fi networks
                Header { icon: "wifi"; title: "Wi-Fi" }
                Text {
                    visible: root.networks.length === 0
                    text: !root.wifiDevice ? "No Wi-Fi device"
                        : !Networking.wifiEnabled ? "Wi-Fi is off"
                        : "Scanning…"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Repeater {
                        // ScriptModel keeps delegates (and a half-typed password) across re-sorts.
                        model: ScriptModel { values: root.networks }

                        WifiRow {
                            required property var modelData
                            Layout.fillWidth: true
                            network: modelData
                            expanded: root.expandedNetwork === modelData.name
                            onExpandRequested: expand => {
                                root.expandedNetwork = expand ? modelData.name : "";
                                if (!expand) frame.forceActiveFocus();
                            }
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
