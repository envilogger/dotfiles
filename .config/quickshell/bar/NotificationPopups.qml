import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.widgets

// New notifications, stacked in the top-right corner of the focused monitor.
PanelWindow {
    id: root

    // At most this many popups; older ones are still in the notification center.
    readonly property int maxPopups: 5

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: NotificationService.popups.length > 0

    anchors {
        top: true
        right: true
    }
    margins {
        top: 12
        right: 12
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    // Keyboard only after clicking into a reply field
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    implicitWidth: 380
    implicitHeight: column.implicitHeight
    color: "transparent"

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            // Newest on top
            model: ScriptModel {
                values: NotificationService.popups.slice(-root.maxPopups).reverse()
            }
            NotificationCard {
                required property var modelData
                Layout.fillWidth: true
                notification: modelData
                popup: true
                onTimedOut: NotificationService.popupTimedOut(modelData)
            }
        }
    }
}
