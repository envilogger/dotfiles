import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.widgets

PanelWindow {
    id: bar

    anchors {
        left: true
        top: true
        bottom: true
    }
    implicitWidth: Theme.barWidth
    color: Theme.bg

    // Top section
    ColumnLayout {
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Theme.padding
        }
        spacing: Theme.spacing

        ArchLogo { Layout.alignment: Qt.AlignHCenter }
        Workspace {
            Layout.alignment: Qt.AlignHCenter
            screen: bar.screen
        }
    }

    // Bottom section
    ColumnLayout {
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: Theme.padding
        }
        spacing: Theme.spacing

        Tray { Layout.alignment: Qt.AlignHCenter }
        Volume { Layout.alignment: Qt.AlignHCenter }
        Network { Layout.alignment: Qt.AlignHCenter }
        Bluetooth { Layout.alignment: Qt.AlignHCenter }
        Battery { Layout.alignment: Qt.AlignHCenter }
        Clock { Layout.alignment: Qt.AlignHCenter }
    }
}
