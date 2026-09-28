pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var focus: ({ state: "unavailable" })
    property real now: Date.now() / 1000
    readonly property bool fresh: now - (focus.observed ?? 0) < 15
    readonly property bool paused: focus.state === "paused"
    readonly property int remaining: fresh ? Math.max(0, Math.ceil((focus.remaining ?? 0)
        - (focus.state === "running" ? Math.max(0, now - focus.observed) : 0))) : 0
    readonly property bool active: fresh && remaining > 0
        && (focus.state === "running" || paused)

    Process {
        id: fetch
        command: ["python3", Quickshell.shellPath("scripts/ticktick-focus.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                root.now = Date.now() / 1000;
                try {
                    root.focus = JSON.parse(text);
                } catch (e) {
                    root.focus = { state: "unavailable" };
                }
            }
        }
    }

    Timer {
        running: true
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!fetch.running) fetch.running = true
    }

    Timer {
        running: true
        interval: 1000
        repeat: true
        onTriggered: root.now = Date.now() / 1000
    }
}
