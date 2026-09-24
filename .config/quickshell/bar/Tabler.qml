pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// All Tabler icons (tabler.io, MIT), from the package's node files in tabler/.
// svg() builds an SVG for one icon; names ending in "-filled" use the filled set.
//
// The node files are large, so the markup of each icon used is cached in
// tabler.json in the shell's cache dir. The node files are only read on a cache
// miss, and dropped again once the cache is written. After updating the node
// files, run `qs ipc -c bar call icons clearCache`.
Singleton {
    id: root

    FileView {
        id: cacheFile
        path: Quickshell.cachePath("tabler.json")
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: outlineFile
        path: Quickshell.shellPath("tabler/nodes-outline.json")
        preload: false
        blockAllReads: true
    }

    FileView {
        id: filledFile
        path: Quickshell.shellPath("tabler/nodes-filled.json")
        preload: false
        blockAllReads: true
    }

    // Loaded on first use, and a plain object so that filling it in from inside a
    // binding doesn't trigger that binding again.
    //   cache: name -> inner SVG markup, still using currentColor
    //   outline, filled: name -> [[tag, { attribute: value }], ...]
    readonly property var store: ({ cache: null, outline: null, filled: null })

    // Bumped by clearCache(); svg() reads it so every icon is rebuilt.
    property int generation: 0

    IpcHandler {
        target: "icons"

        function clearCache(): void {
            root.clearCache();
        }
    }

    function clearCache(): void {
        saveTimer.stop();
        store.cache = {};
        store.outline = null;
        store.filled = null;
        outlineFile.reload();
        filledFile.reload();
        cacheFile.setText("{}");
        generation++;
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: {
            cacheFile.setText(JSON.stringify(root.store.cache));
            root.store.outline = null;
            root.store.filled = null;
        }
    }

    function body(name: string): string {
        const store = root.store;
        if (!store.cache) {
            try {
                store.cache = JSON.parse(cacheFile.text() || "{}");
            } catch (e) {
                store.cache = {};
            }
        }
        if (name in store.cache)
            return store.cache[name];
        const isFilled = name.endsWith("-filled");
        let nodes;
        if (isFilled) {
            if (!store.filled)
                store.filled = JSON.parse(filledFile.text() || "{}");
            nodes = store.filled[name.slice(0, -"-filled".length)];
        } else {
            if (!store.outline)
                store.outline = JSON.parse(outlineFile.text() || "{}");
            nodes = store.outline[name];
        }
        if (!nodes) {
            console.warn(`Tabler: no icon named "${name}"`);
            return "";
        }
        const markup = nodes.map(([tag, attrs]) => {
            const attributes = Object.entries(attrs).map(([k, v]) => `${k}="${v}"`).join(" ");
            return `<${tag} ${attributes}/>`;
        }).join("");
        store.cache[name] = markup;
        saveTimer.restart();
        return markup;
    }

    function svg(name: string, color: color, stroke: real): string {
        generation;
        const markup = body(name);
        if (!markup)
            return "";
        const c = `${color}`;
        const style = name.endsWith("-filled")
            ? `fill="${c}" stroke="none"`
            : `fill="none" stroke="${c}" stroke-width="${stroke}" stroke-linecap="round" stroke-linejoin="round"`;
        return `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" ${style}>${markup.replace(/currentColor/g, c)}</svg>`;
    }
}
