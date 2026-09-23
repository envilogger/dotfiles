import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// Active workspace of the monitor this bar lives on.
Text {
    property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    text: monitor?.activeWorkspace?.name ?? "?"
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: Theme.fontSize + 6
    font.bold: true
}
