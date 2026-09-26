pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// AI plan limits and tokens per day, from scripts/ai-usage.py. Refreshed in the
// background every few minutes, shared by the bar icons and panels on all screens.
Singleton {
    id: root

    // Output of ai-usage.py: { updated, claude: { limits, days, error }, chatgpt: … }
    property var usage: null
    // Highest limit used across all providers, in percent.
    readonly property real maxPercent: {
        const limits = [].concat(usage?.claude?.limits ?? [], usage?.chatgpt?.limits ?? []);
        return Math.max(0, ...limits.map(l => l.percent));
    }

    function refresh() {
        if (!fetch.running) fetch.running = true;
    }

    Process {
        id: fetch
        command: [Quickshell.shellPath("scripts/ai-usage.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const next = JSON.parse(text);
                    // Keep the last known limits when fetching them fails (e.g. rate limited).
                    for (const k of ["claude", "chatgpt"]) {
                        const old = root.usage?.[k]?.limits ?? [];
                        if (next[k]?.error && !next[k].limits.length && old.length) {
                            next[k].limits = old;
                            next[k].error += " (showing last known)";
                        }
                    }
                    root.usage = next;
                } catch (e) {
                    console.warn("AiUsage: can't parse ai-usage.py output:", e);
                }
            }
        }
    }

    Timer {
        running: true
        interval: 3 * 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
