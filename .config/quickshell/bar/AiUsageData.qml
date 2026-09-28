pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// AI plan limits and tokens per day, read from ~/.local/state/quickshell/ai-usage.json.
// That file is written every 90 s by the ai-usage.timer systemd user unit, which runs
// scripts/ai-usage.py --write; the bar never calls the usage endpoint itself, because it
// rate-limits hard (HTTP 429) and every screen's bar would call it again. Shared by the
// bar icons and panels on all screens. To refresh now: systemctl --user start ai-usage.
Singleton {
    id: root

    // Contents of the cache file: { updated, claude: { limits, days, error }, claudeWork:
    // …, chatgpt: … }. One key per tab in AiUsagePanel; claude and claudeWork are the
    // personal and work Claude Code profiles.
    readonly property var providers: ["claude", "claudeWork", "chatgpt"]
    property var usage: null
    // Shown instead of "Loading…" while there is no cache file at all.
    property string error: ""
    // Highest limit used per provider, in percent: { claude: 19, claudeWork: 10, … }.
    readonly property var percents: {
        const out = {};
        for (const k of providers)
            out[k] = Math.max(0, ...(usage?.[k]?.limits ?? []).map(l => l.percent));
        return out;
    }

    FileView {
        id: cache
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/quickshell/ai-usage.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
                root.error = "";
            } catch (e) {
                console.warn("AiUsage: can't parse", path, e);
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                root.error = "No data yet — is ai-usage.timer running?";
            else
                root.error = `Can't read ${path}`;
        }
    }

    // The watcher alone isn't enough: the file doesn't exist before the service's first
    // run, and each run replaces it by rename, which a watcher can lose track of. Rereading
    // a local file this small costs nothing.
    Timer {
        running: true
        interval: 30000
        repeat: true
        onTriggered: cache.reload()
    }
}
