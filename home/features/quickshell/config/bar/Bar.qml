import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.widgets

// Die Bar selbst ist transparent — sichtbar sind nur die Inseln. Drei getrennt
// verankerte Reihen statt einer Layout-Zeile, damit die Uhr exakt in der Mitte
// des Bildschirms bleibt und nicht von der Breite der Nachbarn abhängt.
PanelWindow {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)

    anchors.top: true
    anchors.left: true
    anchors.right: true

    implicitHeight: Theme.barHeight
    color: "transparent"
    exclusiveZone: Theme.barHeight

    Item {
        anchors.fill: parent
        anchors.leftMargin: Theme.barMarginSide
        anchors.rightMargin: Theme.barMarginSide

        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.islandGap

            LauncherButton {}

            Workspaces {
                monitor: root.monitor
            }

            ActiveWindow {
                monitor: root.monitor
            }
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.islandGap

            ClockWidget {
                barWindow: root
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.islandGap

            MediaWidget {
                barWindow: root
            }

            SystemWidget {
                barWindow: root
            }

            TrayWidget {
                barWindow: root
            }

            PowerButton {
                barWindow: root
            }
        }
    }
}
