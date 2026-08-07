import QtQuick
import QtQuick.Layouts
import qs

// Waagerechter Mini-Balken (CPU, RAM …). Bewusst horizontal: zwei senkrechte
// Balken nebeneinander lesen sich in der Bar wie ein Ausrufezeichen.
Item {
    id: root

    property real value: 0
    property color fillColor: Theme.accent

    readonly property real clamped: Math.max(0, Math.min(1, root.value))

    implicitWidth: 20
    implicitHeight: 4

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#14ffffff"
    }

    Rectangle {
        width: Math.max(height, parent.width * root.clamped)
        height: parent.height
        radius: height / 2
        color: root.fillColor

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
