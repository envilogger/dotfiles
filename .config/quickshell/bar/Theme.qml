pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

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
            "warp": "brand-cloudflare",
            "teams-for-linux": "brand-teams",
            "1password": "key"
        })

    readonly property string font: "FiraCode Nerd Font"
    // Propo variant: icon advance width matches the glyph, so icons centre correctly.
    readonly property string iconFont: "FiraCode Nerd Font Propo"
    readonly property int fontSize: 12
    readonly property int iconSize: 18
    readonly property int smallFontSize: 10
    // Line thickness of Tabler outline icons (Tabler's default is 2).
    readonly property real iconStroke: 2

    // Colours come from the base24 palette written by ~/.config/quickshell/apply-theme.sh
    // (from ~/.config/themes/<name>/), and follow it live. Nord until a theme is applied.
    FileView {
        id: paletteFile
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/theme/palette.json`
        watchChanges: true
        onFileChanged: reload()
        blockLoading: true
    }

    readonly property var fallbackPalette: ({
            base00: "#2E3440",
            base01: "#3B4252",
            base03: "#4C566A",
            base05: "#E5E9F0",
            base08: "#BF616A",
            base0A: "#EBCB8B",
            base0B: "#A3BE8C",
            base0C: "#88C0D0"
        })
    readonly property var palette: {
        try {
            return JSON.parse(paletteFile.text()).palette ?? fallbackPalette;
        } catch (e) {
            return fallbackPalette;
        }
    }

    function mix(a: color, b: color, t: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    readonly property color bg: palette.base00
    readonly property color surface: palette.base01
    readonly property color overlay: palette.base03
    readonly property color fg: palette.base05
    // Schemes have no readable muted text colour: base03 is too dim, base04 too bright.
    readonly property color muted: mix(palette.base03, palette.base05, 0.35)
    readonly property color accent: palette.base0C
    readonly property color warn: palette.base0A
    readonly property color crit: palette.base08
    readonly property color good: palette.base0B
}
