import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs

// System tray: every app's icon, except those listed in Theme.trayHidden.
ColumnLayout {
    id: root

    // A hidden name matches if the tray item's id or title contains it, ignoring case
    // (Electron apps use ids like "1Password_status_icon_1").
    function isHidden(item) {
        const names = [item.id, item.title].map(s => (s ?? "").toLowerCase());
        return Theme.trayHidden.some(h => names.some(n => n.includes(h.toLowerCase())));
    }

    readonly property var items: SystemTray.items.values.filter(i => !isHidden(i))

    visible: items.length > 0
    spacing: Theme.spacing

    Repeater {
        // ScriptModel keeps icons (and open menus) as the list changes.
        model: ScriptModel { values: root.items }

        TrayItem {
            required property SystemTrayItem modelData
            Layout.alignment: Qt.AlignHCenter
            item: modelData
        }
    }
}
