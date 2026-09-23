import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs

// Workspaces 1..Theme.workspaceCount. Each shows the icon of its first window, or a dimmed
// rounded square when empty; the monitor's active workspace is highlighted.
// Click: switch to it. Scroll: previous / next workspace.
ColumnLayout {
    id: root

    property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1

    function focusWorkspace(id) {
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        if (ws) ws.activate();
        else if (Hyprland.usingLua) Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        else Hyprland.dispatch(`workspace ${id}`);
    }

    spacing: 4

    WheelHandler {
        onWheel: e => {
            const step = e.angleDelta.y > 0 ? -1 : 1;
            const next = Math.max(1, Math.min(Theme.workspaceCount, root.activeId + step));
            if (next !== root.activeId) root.focusWorkspace(next);
        }
    }

    Repeater {
        model: Theme.workspaceCount

        Item {
            id: cell

            required property int index
            readonly property int wsId: index + 1
            readonly property HyprlandWorkspace ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
            readonly property HyprlandToplevel window: ws?.toplevels.values[0] ?? null
            readonly property string appId: window?.wayland?.appId || window?.lastIpcObject?.class || ""
            readonly property bool active: wsId === root.activeId
            readonly property string iconSource: {
                if (!appId) return "";
                const entry = DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId);
                return Quickshell.iconPath(entry?.icon || appId, true);
            }

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Theme.barWidth - 10
            implicitHeight: Theme.barWidth - 12

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: cell.active ? Theme.surface
                    : area.containsMouse ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.5)
                    : "transparent"
            }

            // App icon: full colour on the active workspace, half-desaturated elsewhere.
            IconImage {
                visible: cell.window !== null && cell.iconSource !== ""
                anchors.centerIn: parent
                implicitSize: Theme.iconSize
                source: cell.iconSource
                asynchronous: true
                opacity: cell.active || area.containsMouse ? 1 : 0.8

                layer.enabled: true
                layer.effect: MultiEffect {
                    saturation: cell.active || area.containsMouse ? 0 : -0.5
                }
            }

            // A window whose app has no icon.
            SvgIcon {
                visible: cell.window !== null && cell.iconSource === ""
                anchors.centerIn: parent
                name: "app-window"
                color: cell.active ? Theme.fg : Theme.muted
            }

            // Empty workspace
            Rectangle {
                visible: cell.window === null
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 3
                color: cell.active ? Theme.accent
                    : area.containsMouse ? Theme.muted
                    : Theme.overlay
            }

            // A window on this workspace wants attention.
            Rectangle {
                visible: cell.ws?.urgent ?? false
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 2
                width: 6
                height: 6
                radius: 3
                color: Theme.crit
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.focusWorkspace(cell.wsId)
            }
        }
    }
}
