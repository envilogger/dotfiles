pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// All Tabler icons (tabler.io, MIT), loaded once from the package's node files in
// tabler/. svg() builds an SVG for one icon; names ending in "-filled" use the
// filled set.
Singleton {
    id: root

    FileView {
        id: outlineFile
        path: Quickshell.shellPath("tabler/nodes-outline.json")
        blockLoading: true
    }

    FileView {
        id: filledFile
        path: Quickshell.shellPath("tabler/nodes-filled.json")
        blockLoading: true
    }

    // name -> [[tag, { attribute: value }], ...]
    readonly property var outline: JSON.parse(outlineFile.text() || "{}")
    readonly property var filled: JSON.parse(filledFile.text() || "{}")

    function svg(name: string, color: color, stroke: real): string {
        const isFilled = name.endsWith("-filled");
        const nodes = isFilled ? filled[name.slice(0, -"-filled".length)] : outline[name];
        if (!nodes) {
            console.warn(`Tabler: no icon named "${name}"`);
            return "";
        }
        const c = `${color}`;
        const body = nodes.map(([tag, attrs]) => {
            const attributes = Object.entries(attrs)
                .map(([k, v]) => `${k}="${String(v).replace(/currentColor/g, c)}"`)
                .join(" ");
            return `<${tag} ${attributes}/>`;
        }).join("");
        const style = isFilled
            ? `fill="${c}" stroke="none"`
            : `fill="none" stroke="${c}" stroke-width="${stroke}" stroke-linecap="round" stroke-linejoin="round"`;
        return `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" ${style}>${body}</svg>`;
    }
}
