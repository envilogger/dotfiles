import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs

// App icon + name + volume row for an app's playback or recording streams. Apps may
// open several streams at once (e.g. Chrome during a call); they're controlled together.
RowLayout {
    id: root

    required property list<PwNode> nodes
    property int iconOn: 0xf057e
    property int iconOff: 0xf0581

    readonly property PwNode node: nodes[0]
    readonly property var props: node?.properties ?? {}
    readonly property string appName: props["application.name"] || node?.description || node?.name || ""
    // Stream titles like "Playback" or "RecordStream" say nothing; show only real ones.
    readonly property string mediaName: {
        const media = props["media.name"] ?? "";
        const generic = /^(playback|record ?stream|audio ?stream|output|input|capture|audio|stream)$/i;
        return nodes.length === 1 && media !== appName && !generic.test(media) ? media : "";
    }
    readonly property string iconSource: {
        const candidates = [
            props["application.icon-name"],
            DesktopEntries.heuristicLookup(appName)?.icon,
            props["application.process.binary"],
        ];
        for (const name of candidates) {
            const path = name ? Quickshell.iconPath(name, true) : "";
            if (path) return path;
        }
        return "";
    }

    spacing: 10

    Item {
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        Layout.alignment: Qt.AlignVCenter

        IconImage {
            anchors.fill: parent
            visible: root.iconSource !== ""
            source: root.iconSource
            implicitSize: 28
            asynchronous: true
        }
        Icon {
            anchors.centerIn: parent
            visible: root.iconSource === ""
            code: 0xf003b
            color: Theme.muted
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
            Layout.fillWidth: true
            text: root.mediaName ? root.appName + " — " + root.mediaName : root.appName
            elide: Text.ElideRight
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.smallFontSize + 1
        }
        VolumeRow {
            Layout.fillWidth: true
            nodes: root.nodes
            iconOn: root.iconOn
            iconOff: root.iconOff
        }
    }
}
