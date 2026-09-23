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

    // Nord (nordtheme.com). Muted text uses a lighter grey than nord3 so it stays readable.
    readonly property color bg: "#2E3440"       // nord0
    readonly property color surface: "#3B4252"  // nord1
    readonly property color overlay: "#4C566A"  // nord3
    readonly property color fg: "#D8DEE9"       // nord4
    readonly property color muted: "#7B88A1"
    readonly property color accent: "#88C0D0"   // nord8
    readonly property color warn: "#EBCB8B"     // nord13
    readonly property color crit: "#BF616A"     // nord11
    readonly property color good: "#A3BE8C"     // nord14
}
