//@ pragma UseQApplication
// Icon names (tray, notifications) resolve in the same theme as GTK apps
//@ pragma IconTheme Adwaita
import QtQuick
import Quickshell

ShellRoot {
    // One bar per connected monitor.
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    // Notification popups and the volume/brightness OSD follow the focused monitor.
    NotificationPopups {}
    Osd {}
}
