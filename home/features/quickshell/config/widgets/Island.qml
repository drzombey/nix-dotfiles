import QtQuick
import QtQuick.Layouts
import qs

// Freischwebender Container ("Insel") in der Bar. Wächst mit seinem Inhalt und
// versteckt sich, wenn nichts drin ist.
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property real pad: Theme.islandPad

    // Über die implizite Breite des Layouts statt über `visibleChildren`:
    // letzteres hat kein Notify-Signal, die Bindung würde nie neu laufen.
    readonly property bool empty: row.implicitWidth <= 0

    implicitWidth: root.empty ? 0 : row.implicitWidth + root.pad * 2
    implicitHeight: Theme.islandHeight
    radius: Theme.islandRadius
    color: Theme.islandBg
    border.width: 1
    border.color: Theme.islandBorder
    opacity: root.empty ? 0 : 1
    visible: opacity > 0.01

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Theme.easing
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.animNormal
        }
    }

    data: [
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Theme.itemGap
        }
    ]
}
