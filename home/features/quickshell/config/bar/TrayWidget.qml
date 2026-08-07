import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs
import qs.widgets
import qs.popups

// System-Tray. Linksklick aktiviert, Rechtsklick öffnet das DBus-Menü; Icons,
// die nur ein Menü anbieten, öffnen es auch mit Linksklick.
Island {
    id: root

    property var barWindow: null

    pad: Theme.islandPad + 4

    Row {
        Layout.alignment: Qt.AlignVCenter
        spacing: 9
        visible: SystemTray.items.values.length > 0

        Repeater {
            model: SystemTray.items

            Item {
                id: slot

                required property SystemTrayItem modelData

                width: 18
                height: 18
                anchors.verticalCenter: parent.verticalCenter

                IconImage {
                    anchors.fill: parent
                    source: slot.modelData.icon
                    asynchronous: true
                    opacity: iconMouse.containsMouse ? 1 : 0.82
                    scale: iconMouse.pressed ? 0.86 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animFast
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                        }
                    }
                }

                MouseArea {
                    id: iconMouse

                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: event => {
                        if (event.button === Qt.MiddleButton) {
                            slot.modelData.secondaryActivate();
                            return;
                        }

                        const wantsMenu = event.button === Qt.RightButton || slot.modelData.onlyMenu;

                        if (wantsMenu) {
                            if (slot.modelData.hasMenu)
                                itemMenu.open = !itemMenu.open;
                        } else {
                            slot.modelData.activate();
                        }
                    }

                    onWheel: event => slot.modelData.scroll(event.angleDelta.y, false)
                }

                TrayMenu {
                    id: itemMenu

                    anchorItem: slot
                    barWindow: root.barWindow
                    handle: slot.modelData.menu
                }
            }
        }
    }
}
