import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets

// Runder Akzent-Button ganz links: Linksklick öffnet den Launcher,
// Rechtsklick ein Terminal.
Rectangle {
    id: root

    Layout.alignment: Qt.AlignVCenter

    implicitWidth: Theme.islandHeight
    implicitHeight: Theme.islandHeight
    radius: Theme.islandRadius
    scale: mouse.pressed ? 0.92 : (mouse.containsMouse ? 1.06 : 1)

    gradient: Gradient {
        orientation: Gradient.Vertical

        GradientStop {
            position: 0
            color: Theme.accentAlt
        }

        GradientStop {
            position: 1
            color: Theme.accent
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Theme.easing
        }
    }

    Icon {
        anchors.centerIn: parent
        text: Theme.iconNix
        font.pixelSize: Theme.iconSizeLarge
        color: Theme.base
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.RightButton)
                Quickshell.execDetached(Theme.terminal);
            else
                Quickshell.execDetached(Theme.launcher);
        }
    }
}
