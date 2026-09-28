import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs

// One notification: image, app name and time, summary, body, action buttons and an
// inline reply field. Click: run the default action. Middle click or ×: dismiss.
// Used by the popups (`popup: true`, hidden after a timeout) and the center.
Rectangle {
    id: root

    required property Notification notification
    property bool popup: false
    // Popup ran out (or was clicked without a default action)
    signal timedOut

    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property var actions: notification?.actions ?? []
    readonly property var defaultAction: actions.find(a => a.identifier === "default") ?? null
    readonly property var buttons: actions.filter(a => a.identifier !== "default")
    readonly property date arrived: NotificationService.arrivedAt[notification?.id] ?? new Date(NaN)
    // True once the reply field has been clicked into. Deliberately `focus` and not
    // `activeFocus`: the popup window only asks the compositor for keyboard because of
    // this, so activeFocus cannot be true yet at the moment it flips.
    readonly property bool replyFocused: reply.focus

    // Image hint first, then the app icon. Either may be a file path or an icon theme
    // name; Quickshell passes the image hint as image://icon/<path or name>.
    readonly property string imageSource: resolveImage(notification?.image) || resolveImage(notification?.appIcon)

    function resolveImage(source: string): string {
        if (!source) return "";
        if (source.startsWith("image://icon/")) source = source.slice("image://icon/".length);
        if (source.startsWith("/")) return "file://" + source;
        if (source.includes("://")) return source;
        return Quickshell.iconPath(source, true);
    }

    implicitWidth: 360
    implicitHeight: content.implicitHeight + 2 * Theme.padding
    radius: Theme.radius
    color: popup ? Theme.bg : Theme.surface
    border.width: 2
    border.color: critical ? Theme.crit : popup ? Theme.surface : "transparent"

    HoverHandler { id: hover }

    // Milliseconds from the sender, 6s by default; critical ones stay until dismissed.
    Timer {
        running: root.popup && !root.critical && !hover.hovered && !reply.activeFocus
        interval: (root.notification?.expireTimeout ?? 0) > 0 ? root.notification.expireTimeout : 6000
        onTriggered: root.timedOut()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) root.notification.dismiss();
            else if (root.defaultAction) root.defaultAction.invoke();
            else if (root.popup) root.timedOut();
        }
    }

    component Button: Rectangle {
        id: button
        property string text
        signal clicked
        implicitWidth: label.implicitWidth + 20
        implicitHeight: label.implicitHeight + 10
        radius: Theme.radius / 2
        color: buttonArea.containsMouse ? Theme.accent : root.popup ? Theme.surface : Theme.overlay

        Text {
            id: label
            anchors.centerIn: parent
            text: button.text
            color: buttonArea.containsMouse ? Theme.bg : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Theme.padding
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Image {
                visible: root.imageSource !== "" && status !== Image.Error
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignTop
                source: root.imageSource
                sourceSize.width: 80
                sourceSize.height: 80
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                // App name · time, close button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: [root.notification?.appName ?? "",
                            isNaN(root.arrived) ? "" : Qt.formatTime(root.arrived, "HH:mm")]
                            .filter(s => s).join(" · ")
                        elide: Text.ElideRight
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.smallFontSize
                    }

                    SvgIcon {
                        name: "x"
                        size: Theme.fontSize + 2
                        color: closeArea.containsMouse ? Theme.accent : Theme.muted

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.notification.dismiss()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notification?.summary ?? ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: root.critical ? Theme.crit : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notification?.body ?? ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: root.popup ? 4 : 8
                    elide: Text.ElideRight
                    color: Theme.fg
                    linkColor: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            visible: root.buttons.length > 0
            spacing: 6

            Repeater {
                model: root.buttons
                Button {
                    required property NotificationAction modelData
                    text: modelData.text
                    onClicked: modelData.invoke()
                }
            }
        }

        // Inline reply (e.g. messengers)
        Rectangle {
            Layout.fillWidth: true
            visible: root.notification?.hasInlineReply ?? false
            implicitHeight: reply.implicitHeight + 14
            radius: Theme.radius / 2
            color: root.popup ? Theme.surface : Theme.bg
            border.width: 1
            border.color: reply.activeFocus ? Theme.accent : "transparent"

            TextInput {
                id: reply
                anchors.left: parent.left
                anchors.right: send.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                color: Theme.fg
                selectionColor: Theme.accent
                selectedTextColor: Theme.bg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                clip: true
                onAccepted: {
                    if (text.trim())
                        root.notification.sendInlineReply(text);
                    // Hand the keyboard back to the window underneath.
                    focus = false;
                }
                Keys.onEscapePressed: focus = false

                Text {
                    visible: !reply.text && !reply.activeFocus
                    text: root.notification?.inlineReplyPlaceholder || "Reply…"
                    color: Theme.muted
                    font: reply.font
                }
            }

            SvgIcon {
                id: send
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 8
                name: "send"
                size: Theme.fontSize + 2
                color: sendArea.containsMouse ? Theme.accent : Theme.muted

                MouseArea {
                    id: sendArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: reply.accepted()
                }
            }
        }
    }
}
