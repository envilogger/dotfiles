import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

// One tray icon. Left click: activate (or open the menu for menu-only items).
// Right click: app menu. Middle click: secondary action. Scroll: passed to the app.
Item {
    id: root

    required property SystemTrayItem item

    // Some apps send "name?path=/dir" for icons outside the theme; load the file directly.
    readonly property string iconSource: {
        const icon = item.icon;
        if (!icon.includes("?path=")) return icon;
        const [name, path] = icon.split("?path=");
        return `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`;
    }

    implicitWidth: Theme.iconSize
    implicitHeight: Theme.iconSize

    // Hover background: icons are images, so they can't take the accent colour.
    Rectangle {
        anchors.centerIn: parent
        width: Theme.barWidth - 10
        height: parent.height + 8
        radius: 6
        color: Theme.surface
        visible: area.containsMouse || menu.visible
    }

    IconImage {
        anchors.fill: parent
        source: root.iconSource
        asynchronous: true
    }

    // Marks apps asking for attention (e.g. unread messages).
    Rectangle {
        visible: root.item.status === Status.NeedsAttention
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: -3
        width: 6
        height: 6
        radius: 3
        color: Theme.crit
    }

    QsMenuAnchor {
        id: menu
        menu: root.item.menu
        anchor.window: root.QsWindow.window
        anchor.rect.x: Theme.barWidth + 8
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
    }

    function openMenu() {
        if (!item.hasMenu) return;
        menu.anchor.rect.y = root.mapToItem(null, 0, 0).y;
        menu.open();
    }

    MouseArea {
        id: area
        // Larger than the icon: the full bar width, and half the gap to neighbouring icons.
        anchors.fill: parent
        anchors.leftMargin: -(Theme.barWidth - root.width) / 2
        anchors.rightMargin: -(Theme.barWidth - root.width) / 2
        anchors.topMargin: -Theme.spacing / 2
        anchors.bottomMargin: -Theme.spacing / 2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && root.item.onlyMenu))
                root.openMenu();
            else if (mouse.button === Qt.LeftButton)
                root.item.activate();
            else
                root.item.secondaryActivate();
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y !== 0) root.item.scroll(wheel.angleDelta.y, false);
            else if (wheel.angleDelta.x !== 0) root.item.scroll(wheel.angleDelta.x, true);
        }
    }
}
