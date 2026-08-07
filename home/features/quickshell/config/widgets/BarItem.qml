import QtQuick
import QtQuick.Layouts
import qs

// Klickbares Pill innerhalb einer Insel: Hover-/Press-Hintergrund, Maus- und
// Scroll-Signale. Inhalt wird als Row angeordnet.
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property real pad: Theme.itemPad
    property bool active: false
    property color activeColor: Theme.press
    // Hintergrund im Ruhezustand — für Elemente, die auch ungenutzt als
    // Bedienelement erkennbar sein sollen.
    property color restColor: "transparent"

    readonly property alias hovered: mouse.containsMouse

    signal activated
    signal secondaryActivated
    signal middleActivated
    signal scrolled(real delta)

    Layout.alignment: Qt.AlignVCenter

    implicitWidth: row.implicitWidth + root.pad * 2
    implicitHeight: Theme.itemHeight
    radius: Theme.itemRadius

    color: root.active ? root.activeColor : (mouse.pressed ? Theme.press : (mouse.containsMouse ? Theme.hover : root.restColor))

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Theme.easing
        }
    }

    data: [
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6
        },
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onClicked: event => {
                if (event.button === Qt.RightButton)
                    root.secondaryActivated();
                else if (event.button === Qt.MiddleButton)
                    root.middleActivated();
                else
                    root.activated();
            }

            onWheel: event => root.scrolled(event.angleDelta.y)
        }
    ]
}
