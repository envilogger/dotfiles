import QtQuick
import qs

// Tabler icon by name (see tabler.io/icons), drawn in `color`. Names ending in
// "-filled" use the filled variant.
Item {
    id: root

    property string name
    property color color: Theme.fg
    property int size: Theme.iconSize

    implicitWidth: size
    implicitHeight: size

    Image {
        anchors.fill: parent
        sourceSize.width: root.size
        sourceSize.height: root.size
        source: {
            const svg = root.name ? Tabler.svg(root.name, root.color, Theme.iconStroke) : "";
            return svg ? "data:image/svg+xml;utf8," + encodeURIComponent(svg) : "";
        }
    }
}
