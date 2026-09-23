import QtQuick
import Quickshell.Services.UPower
import qs

Column {
    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property int percent: Math.round((dev?.percentage ?? 0) * 100)
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
        || dev?.state === UPowerDeviceState.PendingCharge
        || dev?.state === UPowerDeviceState.FullyCharged

    visible: dev?.isPresent ?? false
    spacing: 0

    Icon {
        anchors.horizontalCenter: parent.horizontalCenter
        // md-battery_10 .. md-battery_90 are consecutive codepoints.
        code: parent.charging ? 0xf0084
            : parent.percent >= 95 ? 0xf0079
            : parent.percent < 5 ? 0xf008e
            : 0xf007a + Math.max(0, Math.min(8, Math.floor(parent.percent / 10) - 1))
        color: parent.charging ? Theme.good
            : parent.percent <= 10 ? Theme.crit
            : parent.percent <= 25 ? Theme.warn
            : Theme.fg
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: parent.percent + "%"
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.smallFontSize
    }
}
