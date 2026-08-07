import QtQuick
import QtQuick.Layouts
import qs

// Schlanker Slider für Lautstärke/Helligkeit. Gibt Änderungen als Signal
// weiter statt `value` selbst zu setzen — die Quelle bleibt die Wahrheit.
Item {
    id: root

    property real value: 0
    property color fillColor: Theme.accent
    property color fillColorAlt: Theme.accentAlt
    property real step: 0.05

    readonly property real clamped: Math.max(0, Math.min(1, root.value))
    readonly property alias hovered: mouse.containsMouse

    signal moved(real value)

    Layout.fillWidth: true
    implicitHeight: 22
    implicitWidth: 140

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: mouse.containsMouse || mouse.pressed ? 9 : 7
        radius: height / 2
        color: Theme.track

        Behavior on height {
            NumberAnimation {
                duration: Theme.animFast
            }
        }

        Rectangle {
            id: fill

            width: Math.max(height, track.width * root.clamped)
            height: parent.height
            radius: parent.radius

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: root.fillColor
                }

                GradientStop {
                    position: 1
                    color: root.fillColorAlt
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animFast
                }
            }
        }

        Rectangle {
            x: Math.max(0, Math.min(track.width - width, fill.width - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 12
            radius: 6
            color: Theme.text
            opacity: mouse.containsMouse || mouse.pressed ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animFast
                }
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        anchors.topMargin: -4
        anchors.bottomMargin: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function apply(x: real): void {
            root.moved(Math.max(0, Math.min(1, x / root.width)));
        }

        onPressed: event => apply(event.x)
        onPositionChanged: event => {
            if (mouse.pressed)
                apply(event.x);
        }
        onWheel: event => {
            const dir = event.angleDelta.y > 0 ? 1 : -1;
            root.moved(Math.max(0, Math.min(1, root.clamped + dir * root.step)));
        }
    }
}
