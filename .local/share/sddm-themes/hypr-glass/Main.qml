// SDDM greeter styled after ~/.config/hypr/hyprlock.conf: blurred wallpaper, clock,
// date, pill-shaped password field, user below it. Session and power in the corners.
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "black"

    readonly property string fontFamily: config.font || "Inter"
    readonly property color white: Qt.rgba(1, 1, 1, 0.95)
    readonly property color dimWhite: Qt.rgba(1, 1, 1, 0.7)
    readonly property color checkColor: Qt.rgba(130 / 255, 170 / 255, 1, 0.9)
    readonly property color failColor: Qt.rgba(240 / 255, 100 / 255, 100 / 255, 0.9)
    readonly property color capsColor: Qt.rgba(230 / 255, 190 / 255, 90 / 255, 0.9)

    property int userIndex: Math.max(userModel.lastIndex, 0)
    property int sessionIndex: Math.max(sessionModel.lastIndex, 0)
    property bool checking: false
    property bool failed: false

    // Hidden delegates so names can be read by index
    Repeater { id: users; model: userModel; delegate: Item { property string userName: model.name } }
    Repeater { id: sessions; model: sessionModel; delegate: Item { property string sessionName: model.name } }

    readonly property string userName: users.count > 0 && users.itemAt(userIndex)
        ? users.itemAt(userIndex).userName : userModel.lastUser
    readonly property string sessionName: sessions.count > 0 && sessions.itemAt(sessionIndex)
        ? sessions.itemAt(sessionIndex).sessionName : ""

    function login() {
        if (password.text === "" || checking) return
        checking = true
        failed = false
        sddm.login(userName, password.text, sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            checking = false
            failed = true
            password.clear()
            password.forceActiveFocus()
            shake.start()
        }
        function onLoginSucceeded() { checking = false }
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    // Oversized so the blur doesn't fade the screen edges
    MultiEffect {
        anchors.fill: parent
        anchors.margins: -blurMax
        source: wallpaper
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        brightness: -0.4
        saturation: 0.2
    }

    component Shadowed: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.5)
        shadowBlur: 0.6
        shadowVerticalOffset: 1
        shadowHorizontalOffset: 0
    }

    Column {
        id: center
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 0

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.weight: Font.Light
            font.pixelSize: 146
            color: root.white
            text: Qt.formatTime(new Date(), "HH:mm")
            layer.enabled: true
            layer.effect: Shadowed {}
        }

        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: 26
            color: Qt.rgba(1, 1, 1, 0.8)
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
            layer.enabled: true
            layer.effect: Shadowed {}
        }

        Item { width: 1; height: 72 }

        TextField {
            id: password
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            height: 56
            focus: true
            echoMode: TextInput.Password
            passwordCharacter: "●"
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            font.family: root.fontFamily
            font.pixelSize: 16
            font.letterSpacing: 4
            color: root.white
            selectionColor: root.checkColor
            enabled: !root.checking
            onAccepted: root.login()
            onTextEdited: root.failed = false

            background: Rectangle {
                radius: height / 2
                color: Qt.rgba(20 / 255, 20 / 255, 24 / 255, 0.45)
                border.width: 2
                border.color: root.checking ? root.checkColor
                    : root.failed ? root.failColor
                    : keyboard.capsLock ? root.capsColor
                    : Qt.rgba(1, 1, 1, 0.25)
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            // Own placeholder: the built-in one hides on focus when centred
            Text {
                anchors.centerIn: parent
                visible: password.text === ""
                font.family: root.fontFamily
                font.pixelSize: 16
                color: root.failed ? root.failColor : Qt.rgba(1, 1, 1, 0.67)
                text: root.failed ? "Wrong password" : "Password"
            }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: password; property: "anchors.horizontalCenterOffset"; to: -12; duration: 50 }
                NumberAnimation { target: password; property: "anchors.horizontalCenterOffset"; to: 12; duration: 70 }
                NumberAnimation { target: password; property: "anchors.horizontalCenterOffset"; to: -6; duration: 70 }
                NumberAnimation { target: password; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
            }
        }

        Item { width: 1; height: 16 }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.weight: Font.Medium
            font.pixelSize: 18
            color: root.dimWhite
            text: root.userName + (users.count > 1 ? "  ›" : "")
            layer.enabled: true
            layer.effect: Shadowed {}
            MouseArea {
                anchors.fill: parent
                enabled: users.count > 1
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.userIndex = (root.userIndex + 1) % users.count; password.forceActiveFocus() }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 8
            font.family: root.fontFamily
            font.pixelSize: 14
            color: root.capsColor
            text: "Caps Lock is on"
            opacity: keyboard.capsLock ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date()
            clock.text = Qt.formatTime(now, "HH:mm")
            date.text = Qt.formatDate(now, "dddd, d MMMM")
        }
    }

    component CornerButton: Text {
        id: btn
        signal clicked
        font.family: root.fontFamily
        font.pixelSize: 15
        color: area.containsMouse ? root.white : root.dimWhite
        layer.enabled: true
        layer.effect: Shadowed {}
        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    CornerButton {
        anchors { left: parent.left; bottom: parent.bottom; margins: 32 }
        text: root.sessionName + (sessions.count > 1 ? "  ›" : "")
        onClicked: { root.sessionIndex = (root.sessionIndex + 1) % sessions.count; password.forceActiveFocus() }
    }

    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 32 }
        spacing: 28
        CornerButton { text: "Restart"; visible: sddm.canReboot; onClicked: sddm.reboot() }
        CornerButton { text: "Shut down"; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
    }

    Component.onCompleted: password.forceActiveFocus()
}
