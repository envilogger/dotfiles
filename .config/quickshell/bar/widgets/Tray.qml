import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs

// System tray. Apps listed in Theme.trayPinned are always shown; the rest are hidden
// behind a chevron that expands them inline. Hidden apps asking for attention are
// shown anyway.
ColumnLayout {
    id: root

    property bool expanded: false

    // A pinned name matches if the tray item's id or title contains it, ignoring case
    // (Electron apps use ids like "1Password_status_icon_1").
    function isPinned(item) {
        const names = [item.id, item.title].map(s => (s ?? "").toLowerCase());
        return Theme.trayPinned.some(p => names.some(n => n.includes(p.toLowerCase())));
    }

    readonly property var items: SystemTray.items.values
    readonly property var pinned: items.filter(i => isPinned(i))
    readonly property var hidden: items.filter(i => !isPinned(i))
    readonly property var shown: pinned.concat(expanded ? hidden
        : hidden.filter(i => i.status === Status.NeedsAttention))

    visible: items.length > 0
    spacing: Theme.spacing

    // Collapse when there's nothing left to hide.
    onHiddenChanged: if (hidden.length === 0) expanded = false

    Repeater {
        // ScriptModel keeps icons (and open menus) as the list changes.
        model: ScriptModel { values: root.shown }

        TrayItem {
            required property SystemTrayItem modelData
            Layout.alignment: Qt.AlignHCenter
            item: modelData
        }
    }

    // Expand / collapse
    Icon {
        id: toggle
        visible: root.hidden.length > 0
        Layout.alignment: Qt.AlignHCenter
        code: root.expanded ? 0xf0143 : 0xf0140
        color: toggleArea.containsMouse ? Theme.accent : Theme.muted

        MouseArea {
            id: toggleArea
            anchors.fill: parent
            anchors.leftMargin: -(Theme.barWidth - toggle.width) / 2
            anchors.rightMargin: -(Theme.barWidth - toggle.width) / 2
            anchors.topMargin: -Theme.spacing / 2
            anchors.bottomMargin: -Theme.spacing / 2
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }
}
