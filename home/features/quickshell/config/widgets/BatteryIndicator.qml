import QtQuick
import QtQuick.Layouts
import qs
import qs.services

// Gezeichnete Batterie statt Icon-Font: der Füllstand ist dadurch stufenlos
// und der Ladeblitz liegt sauber darüber.
Item {
    id: root

    readonly property bool present: Battery.present
    readonly property real level: Battery.level
    readonly property bool charging: Battery.charging
    readonly property bool full: Battery.full

    readonly property color levelColor: {
        if (root.charging || root.full)
            return Theme.green;
        if (root.level <= 0.12)
            return Theme.red;
        if (root.level <= 0.25)
            return Theme.orange;

        return Theme.text;
    }

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: 27
    implicitHeight: 14

    Rectangle {
        id: shell

        width: 24
        height: 14
        radius: 4.5
        color: "transparent"
        border.width: 1.4
        border.color: Theme.muted

        Rectangle {
            x: 2.4
            y: 2.4
            width: Math.max(height, (shell.width - 4.8) * root.level)
            height: shell.height - 4.8
            radius: 2.4
            color: root.levelColor

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animSlow
                    easing.type: Theme.easing
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animNormal
                }
            }
        }
    }

    Rectangle {
        x: shell.width + 0.6
        anchors.verticalCenter: shell.verticalCenter
        width: 2.2
        height: 5.5
        radius: 1.1
        color: Theme.muted
    }

    // Icon statt Text: nur dort wird die Ink-Fläche der Glyphe zentriert.
    Icon {
        anchors.centerIn: shell
        visible: root.charging
        text: Theme.iconBolt
        font.pixelSize: 11
        color: Theme.base
        style: Text.Outline
        styleColor: "#80000000"
    }
}
