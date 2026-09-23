pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property int barWidth: 42
    readonly property int spacing: 14
    readonly property int padding: 12
    readonly property int radius: 10

    readonly property string font: "FiraCode Nerd Font"
    // Propo variant: icon advance width matches the glyph, so icons centre correctly.
    readonly property string iconFont: "FiraCode Nerd Font Propo"
    readonly property int fontSize: 12
    readonly property int iconSize: 18
    readonly property int smallFontSize: 10

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
