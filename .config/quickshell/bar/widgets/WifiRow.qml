import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs

// One Wi-Fi network. Click: connect (or disconnect if connected). Secured networks
// without saved credentials expand a password field first.
Rectangle {
    id: root

    required property var network
    // Whether the password field is shown; owned by the list so only one is open.
    property bool expanded: false
    signal expandRequested(bool expand)

    readonly property real strength: network.signalStrength
    readonly property bool secured: network.security !== WifiSecurityType.Open
        && network.security !== WifiSecurityType.Owe
    readonly property bool busy: network.stateChanging
        || network.state === ConnectionState.Connecting
    property string error: ""

    implicitHeight: column.implicitHeight + 10
    radius: 6
    color: mouse.containsMouse || expanded ? Theme.overlay : "transparent"

    function activate() {
        error = "";
        if (network.connected) {
            network.disconnect();
        } else if (network.known || !secured) {
            network.connect();
        } else {
            expandRequested(!expanded);
        }
    }

    function submit() {
        if (password.text.length === 0) return;
        error = "";
        network.connectWithPsk(password.text);
        password.text = "";
        expandRequested(false);
    }

    onExpandedChanged: if (expanded) password.forceActiveFocus()

    Connections {
        target: root.network
        function onConnectionFailed(reason) {
            root.error = reason === ConnectionFailReason.NoSecrets ? "Wrong password"
                : "Failed: " + ConnectionFailReason.toString(reason);
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activate()
    }

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Icon {
                code: root.strength < 0.2 ? 0xf092e
                    : root.strength < 0.4 ? 0xf091f
                    : root.strength < 0.6 ? 0xf0922
                    : root.strength < 0.8 ? 0xf0925
                    : 0xf0928
                font.pixelSize: Theme.fontSize + 4
                color: root.network.connected ? Theme.accent : Theme.fg
                Layout.preferredWidth: 20
            }

            Text {
                Layout.fillWidth: true
                text: root.network.name
                elide: Text.ElideRight
                color: root.network.connected || root.network.known ? Theme.fg : Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.bold: root.network.connected
            }

            Text {
                visible: root.busy || root.error !== ""
                text: root.error !== "" ? root.error : "Connecting…"
                color: root.error !== "" ? Theme.crit : Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.smallFontSize
            }

            // Saved network
            Icon {
                visible: root.network.known && !root.network.connected
                code: 0xf04ce
                font.pixelSize: Theme.fontSize + 2
                color: Theme.muted
            }

            Icon {
                visible: root.secured
                code: 0xf033e
                font.pixelSize: Theme.fontSize + 2
                color: Theme.muted
            }
        }

        // Password field for unknown secured networks.
        Rectangle {
            visible: root.expanded
            Layout.fillWidth: true
            implicitHeight: password.implicitHeight + 12
            radius: 6
            color: Theme.bg
            border.color: password.activeFocus ? Theme.accent : Theme.surface
            border.width: 1

            TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Theme.fg
                selectionColor: Theme.accent
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                clip: true
                onAccepted: root.submit()
                Keys.onEscapePressed: event => {
                    root.expandRequested(false);
                    event.accepted = true;
                }

                Text {
                    visible: password.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Password, Enter to connect"
                    color: Theme.muted
                    font: password.font
                }
            }
        }
    }
}
