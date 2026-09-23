pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property int barWidth: 42
    readonly property int spacing: 14
    readonly property int padding: 12
    readonly property int radius: 10
    // Popup panels scroll once taller than this fraction of the screen height.
    readonly property real panelMaxHeight: 0.5
    // Workspaces shown in the bar (1..n), matching the mainMod + 0-9 binds.
    readonly property int workspaceCount: 10
    // Tray apps to hide completely. An entry matches if the tray item's id or title
    // contains it, ignoring case (e.g. "1password").
    readonly property list<string> trayHidden: []
    // Tray apps drawn with a Tabler icon (matched like trayHidden) instead of
    // their own. Apps without one are shown at half colour, full colour on hover.
    readonly property var trayIcons: ({
        "teams-for-linux": "brand-teams",
    })

    readonly property string font: "FiraCode Nerd Font"
    // Propo variant: icon advance width matches the glyph, so icons centre correctly.
    readonly property string iconFont: "FiraCode Nerd Font Propo"
    readonly property int fontSize: 12
    readonly property int iconSize: 18
    readonly property int smallFontSize: 10
    // Line thickness of Tabler outline icons (Tabler's default is 2).
    readonly property real iconStroke: 2

    readonly property color bg: "#1e1e2e"
    readonly property color surface: "#313244"
    readonly property color overlay: "#45475a"
    readonly property color fg: "#cdd6f4"
    readonly property color muted: "#6c7086"
    readonly property color accent: "#89b4fa"
    readonly property color warn: "#f9e2af"
    readonly property color crit: "#f38ba8"
    readonly property color good: "#a6e3a1"
}
