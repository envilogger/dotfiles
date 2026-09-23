import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Tabler outline icon from icons/<name>.svg, drawn in `color`. The SVGs use
// "currentColor" for their strokes, which is replaced with the colour.
Item {
    id: root

    property string name
    property color color: Theme.fg
    property int size: Theme.iconSize

    implicitWidth: size
    implicitHeight: size

    FileView {
        id: file
        path: root.name ? Quickshell.shellPath(`icons/${root.name}.svg`) : ""
        blockLoading: true
    }

    Image {
        anchors.fill: parent
        sourceSize.width: root.size
        sourceSize.height: root.size
        source: {
            const svg = file.text();
            return svg ? "data:image/svg+xml;utf8," + encodeURIComponent(svg.replace(/currentColor/g, `${root.color}`)) : "";
        }
    }
}
