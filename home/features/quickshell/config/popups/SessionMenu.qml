import QtQuick
import Quickshell
import qs
import qs.widgets

// Sitzungsaktionen als Kachelreihe. Abmelden geht über `uwsm stop`, weil
// Hyprland hier mit withUWSM startet und die Session-Units mitaufgeräumt werden
// müssen.
PopupSurface {
    id: root

    // Breit genug für die längste Beschriftung ("Bereitschaft").
    readonly property int tile: 70
    readonly property var actions: [
        {
            label: "Sperren",
            glyph: Theme.iconLock,
            tint: Theme.accent,
            command: ["loginctl", "lock-session"]
        },
        {
            label: "Bereitschaft",
            glyph: Theme.iconSleep,
            tint: Theme.accentAlt,
            command: ["systemctl", "suspend"]
        },
        {
            label: "Abmelden",
            glyph: Theme.iconLogout,
            tint: Theme.yellow,
            command: ["uwsm", "stop"]
        },
        {
            label: "Neustart",
            glyph: Theme.iconRestart,
            tint: Theme.orange,
            command: ["systemctl", "reboot"]
        },
        {
            label: "Aus",
            glyph: Theme.iconPower,
            tint: Theme.red,
            command: ["systemctl", "poweroff"]
        }
    ]

    surfaceWidth: root.actions.length * root.tile + (root.actions.length - 1) * 6 + Theme.popupPad * 2
    surfaceHeight: root.tile + Theme.popupPad * 2

    Row {
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.actions

            Rectangle {
                id: tile

                required property var modelData

                width: root.tile
                height: root.tile
                radius: 12
                color: tileMouse.containsMouse ? tile.modelData.tint : Theme.track
                scale: tileMouse.pressed ? 0.94 : 1

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animFast
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animFast
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.glyph
                        font.pixelSize: 19
                        boxWidth: 22
                        color: tileMouse.containsMouse ? Theme.base : Theme.text
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.label
                        font.pixelSize: Theme.fontSizeSmall - 1
                        color: tileMouse.containsMouse ? Theme.base : Theme.subtext
                    }
                }

                MouseArea {
                    id: tileMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.open = false;
                        Quickshell.execDetached(tile.modelData.command);
                    }
                }
            }
        }
    }
}
