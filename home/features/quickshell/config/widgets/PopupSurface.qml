import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// Popup unter einem Bar-Element: abgerundete Fläche, Ein-/Ausblend-Animation
// und Klick-daneben-schließt über den Hyprland-Focus-Grab.
//
// Der Focus-Grab schließt bewusst *nicht* bei Klicks auf die Bar selbst — sonst
// würde der auslösende Button das Popup schließen und der Klick es sofort
// wieder öffnen.
PopupWindow {
    id: root

    property Item anchorItem
    property var barWindow: null
    property real surfaceWidth: 320
    property real surfaceHeight: 200
    property bool open: false

    default property alias content: surface.data

    // Reserve oben für die Einblend-Verschiebung, damit nichts abgeschnitten wird.
    readonly property int slide: 10

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: root.surfaceWidth
    implicitHeight: root.surfaceHeight + root.slide
    color: "transparent"
    visible: root.open || closeTimer.running

    property bool revealed: false

    onOpenChanged: {
        if (root.open) {
            closeTimer.stop();
            revealTimer.restart();
        } else {
            root.revealed = false;
            closeTimer.restart();
        }
    }

    data: [
        Timer {
            id: revealTimer
            interval: 16
            onTriggered: root.revealed = true
        },
        Timer {
            id: closeTimer
            interval: Theme.animNormal + 60
        },
        // Der Grab wird erst aktiviert, wenn die Layer-Surface schon steht
        // (`revealed` kommt einen Frame später) — sonst weist Hyprland ihn ab
        // und `cleared` schließt das Popup sofort wieder.
        HyprlandFocusGrab {
            active: root.revealed
            windows: root.barWindow ? [root, root.barWindow] : [root]
            onCleared: root.open = false
        },
        Rectangle {
            id: surface

            width: root.surfaceWidth
            height: root.surfaceHeight
            y: root.revealed ? root.slide : 0
            radius: Theme.popupRadius
            color: Theme.popupBg
            border.width: 1
            border.color: Theme.popupBorder
            opacity: root.revealed ? 1 : 0
            transformOrigin: Item.Top
            scale: root.revealed ? 1 : 0.96

            Behavior on y {
                NumberAnimation {
                    duration: Theme.animNormal
                    easing.type: Theme.easing
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animFast
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animNormal
                    easing.type: Theme.easing
                }
            }
        }
    ]
}
