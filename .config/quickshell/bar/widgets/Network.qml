import QtQuick
import Quickshell.Networking
import qs

Icon {
    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var wifiNet: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property real strength: wifiNet?.signalStrength ?? 0

    code: wired ? 0xf0200
        : !wifi ? 0xf05aa
        : strength < 0.2 ? 0xf092e
        : strength < 0.4 ? 0xf091f
        : strength < 0.6 ? 0xf0922
        : strength < 0.8 ? 0xf0925
        : 0xf0928
    color: wired || wifi ? Theme.fg : Theme.muted
}
