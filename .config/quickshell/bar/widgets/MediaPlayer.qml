import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs

// Now-playing card for MPRIS players (browsers, Spotify, ...): cover, track info,
// seek bar, times and playback controls. Follows whichever player is playing; the
// arrows switch between players when there are several.
ColumnLayout {
    id: root

    // Refresh the position only while shown.
    property bool active: true

    // Players with something loaded.
    readonly property list<MprisPlayer> players: Mpris.players.values
        .filter(p => p.playbackState !== MprisPlaybackState.Stopped || p.trackTitle !== "")

    // Player picked with the arrows; cleared when any player starts playing.
    property MprisPlayer pinned: null
    // Last player that was playing, so pausing doesn't switch away from it.
    property MprisPlayer lastActive: null

    readonly property MprisPlayer player: (players.includes(pinned) ? pinned : null)
        ?? players.find(p => p.isPlaying)
        ?? (players.includes(lastActive) ? lastActive : null)
        ?? players[0]
        ?? null

    readonly property bool hasLength: (player?.lengthSupported ?? false) && player.length > 0
    readonly property string iconSource: {
        const identity = player?.identity ?? "";
        // Some players (Chrome) set no desktop entry and an identity ("Chrome") that
        // only partially matches the app name ("Google Chrome").
        const entry = DesktopEntries.heuristicLookup(player?.desktopEntry || identity)
            ?? (identity ? DesktopEntries.applications.values
                .find(e => e.name.toLowerCase().includes(identity.toLowerCase())) : null);
        return entry?.icon ? Quickshell.iconPath(entry.icon, true) : "";
    }

    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor(s / 60) % 60;
        const ss = String(s % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${ss}` : `${m}:${ss}`;
    }

    function cycle(step) {
        const i = players.indexOf(player);
        pinned = players[(i + step + players.length) % players.length];
    }

    visible: player !== null
    spacing: 8

    Instantiator {
        model: Mpris.players
        Connections {
            required property MprisPlayer modelData
            target: modelData
            function onIsPlayingChanged() {
                if (!modelData.isPlaying) return;
                root.lastActive = modelData;
                root.pinned = null;
            }
        }
    }

    // MPRIS doesn't push position updates; poll while playing.
    Timer {
        running: root.active && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player.positionChanged()
    }
    onActiveChanged: if (active) player?.positionChanged()

    component Button: Icon {
        id: button
        signal clicked()

        color: !enabled ? Theme.overlay
            : buttonMouse.containsMouse ? Theme.accent
            : Theme.fg

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    // Cover + track info
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ClippingRectangle {
            implicitWidth: 56
            implicitHeight: 56
            radius: 6
            color: Theme.surface

            Icon {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                code: 0xf075a
                color: Theme.muted
                font.pixelSize: 24
            }

            Image {
                id: cover
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 112
                sourceSize.height: 112
                asynchronous: true
                cache: false
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Unknown title"
                elide: Text.ElideRight
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                font.bold: true
            }
            Text {
                visible: text !== ""
                Layout.fillWidth: true
                text: root.player?.trackArtist ?? ""
                elide: Text.ElideRight
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                IconImage {
                    visible: root.iconSource !== ""
                    source: root.iconSource
                    implicitSize: 14
                }
                Text {
                    Layout.fillWidth: true
                    text: root.player?.identity ?? ""
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.smallFontSize
                }

                // Player switcher
                Button {
                    visible: root.players.length > 1
                    code: 0xf0141
                    font.pixelSize: Theme.fontSize + 2
                    onClicked: root.cycle(-1)
                }
                Text {
                    visible: root.players.length > 1
                    text: `${root.players.indexOf(root.player) + 1}/${root.players.length}`
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.smallFontSize
                }
                Button {
                    visible: root.players.length > 1
                    code: 0xf0142
                    font.pixelSize: Theme.fontSize + 2
                    onClicked: root.cycle(1)
                }
            }
        }
    }

    // Seek bar
    Slider {
        visible: root.hasLength
        Layout.fillWidth: true
        enabled: root.player?.canSeek ?? false
        value: root.hasLength ? root.player.position / root.player.length : 0
        onMoved: v => root.player.position = v * root.player.length
    }

    // Times + controls
    Item {
        Layout.fillWidth: true
        implicitHeight: controls.implicitHeight

        Text {
            visible: root.hasLength
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.formatTime(root.player?.position ?? 0)
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.smallFontSize
        }

        RowLayout {
            id: controls
            anchors.centerIn: parent
            spacing: 18

            Button {
                code: 0xf04ae
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }
            Button {
                code: root.player?.isPlaying ? 0xf03e4 : 0xf040a
                font.pixelSize: Theme.iconSize + 6
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player.togglePlaying()
            }
            Button {
                code: 0xf04ad
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
        }

        Text {
            visible: root.hasLength
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.formatTime(root.player?.length ?? 0)
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.smallFontSize
        }
    }
}
