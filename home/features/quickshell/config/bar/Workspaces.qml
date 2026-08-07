import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.widgets

// Workspace-Pills: der aktive wird breiter und bekommt den Akzent-Verlauf.
// Hyprland hält leere Workspaces nicht am Leben, deshalb werden 1..n immer
// angezeigt und alles darüber nur, solange es existiert.
Island {
    id: root

    required property HyprlandMonitor monitor

    readonly property var entries: {
        const byId = {};

        for (const ws of Hyprland.workspaces.values) {
            if (ws.id < 1)
                continue;
            if (root.monitor && ws.monitor && ws.monitor.id !== root.monitor.id)
                continue;

            byId[ws.id] = ws;
        }

        const ids = [];
        for (let i = 1; i <= Theme.pinnedWorkspaces; i++)
            ids.push(i);
        for (const key in byId) {
            const id = parseInt(key);
            if (!ids.includes(id))
                ids.push(id);
        }
        ids.sort((a, b) => a - b);

        return ids.map(id => ({
                    id: id,
                    ws: byId[id] ?? null
                }));
    }

    Row {
        id: strip

        Layout.alignment: Qt.AlignVCenter
        spacing: 4

        // Scrollen über den Pills wechselt den Workspace. WheelHandler statt
        // MouseArea, weil ein Handler keinen Layout-Slot belegt.
        WheelHandler {
            onWheel: event => Hyprland.dispatch(event.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
        }

        Repeater {
            model: root.entries

            Rectangle {
                id: pill

                required property var modelData

                readonly property var ws: pill.modelData.ws
                readonly property bool occupied: !!pill.ws
                readonly property bool current: !!pill.ws && pill.ws.active
                readonly property bool urgent: !!pill.ws && pill.ws.urgent

                width: pill.current ? 32 : 22
                height: 22
                radius: 11

                color: pill.urgent ? Theme.red : (pill.occupied ? Theme.track : "transparent")

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

                // Akzent-Verlauf des aktiven Pills. Gradients lassen sich nicht
                // animieren, also wird stattdessen die Deckkraft überblendet.
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    opacity: pill.current ? 1 : 0

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: Theme.accent
                        }

                        GradientStop {
                            position: 1
                            color: Theme.accentAlt
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animNormal
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Theme.hover
                    opacity: hover.containsMouse && !pill.current ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animFast
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: pill.modelData.id
                    font.pixelSize: Theme.fontSizeSmall + 1
                    font.weight: pill.current ? Font.Bold : Font.Medium
                    color: pill.current ? Theme.base : (pill.urgent ? Theme.base : (pill.occupied ? Theme.text : Theme.muted))

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animNormal
                        }
                    }
                }

                MouseArea {
                    id: hover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`workspace ${pill.modelData.id}`)
                }
            }
        }
    }
}
