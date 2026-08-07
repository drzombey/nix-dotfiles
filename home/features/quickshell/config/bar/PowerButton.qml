import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets
import qs.popups

// Power-Symbol ganz rechts; öffnet die Sitzungsaktionen.
// Runde Insel in der Größe des Nix-Buttons, damit beide Enden der Bar gleich
// aussehen — deshalb feste Breite statt der inhaltsabhängigen der Insel.
Island {
    id: root

    property var barWindow: null

    pad: 0
    implicitWidth: Theme.islandHeight

    BarItem {
        id: item

        implicitWidth: Theme.islandHeight
        implicitHeight: Theme.islandHeight
        radius: Theme.islandRadius
        active: session.open
        activeColor: Theme.red
        restColor: Theme.track
        onActivated: session.open = !session.open

        // Volle Textfarbe und dieselbe Größe wie das Nix-Logo gegenüber: als
        // gedämpftes Icon in Theme.subtext war der dünne Ring am Bildschirmrand
        // praktisch nicht zu erkennen.
        Icon {
            Layout.alignment: Qt.AlignVCenter
            text: Theme.iconPower
            font.pixelSize: Theme.iconSizeLarge
            color: session.open ? Theme.base : (item.hovered ? Theme.red : Theme.text)
        }
    }

    SessionMenu {
        id: session

        anchorItem: item
        barWindow: root.barWindow
    }
}
