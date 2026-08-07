import QtQuick
import Quickshell
import qs
import qs.widgets

// Rendert einen DBus-Menü-Level (Tray-Kontextmenüs) im Design der Shell.
// Untermenüs klappen eingerückt auf; die Rekursion ist über `depth` begrenzt und
// läuft lazy über einen Loader.
Column {
    id: root

    property var handle: null
    property int depth: 0
    property real rowWidth: 220

    signal closeRequested

    readonly property int maxDepth: 2

    spacing: 1

    QsMenuOpener {
        id: opener

        menu: root.handle
    }

    Repeater {
        model: opener.children

        Column {
            id: entry

            required property var modelData

            readonly property bool separator: entry.modelData?.isSeparator ?? false
            readonly property bool expandable: (entry.modelData?.hasChildren ?? false) && root.depth < root.maxDepth

            property bool expanded: false

            width: root.rowWidth
            spacing: 1

            Item {
                width: parent.width
                height: 9
                visible: entry.separator

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    height: 1
                    color: Theme.popupBorder
                }
            }

            Rectangle {
                width: parent.width
                height: 27
                radius: 8
                visible: !entry.separator
                opacity: (entry.modelData?.enabled ?? true) ? 1 : 0.4
                color: rowMouse.containsMouse ? Theme.hover : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animFast
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 7

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 15
                        height: 15
                        sourceSize.width: 15
                        sourceSize.height: 15
                        fillMode: Image.PreserveAspectFit
                        source: entry.modelData?.icon ?? ""
                        visible: source.toString() !== ""
                    }

                    // Checkbox/Radio des Menüeintrags
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 13
                        height: 13
                        radius: (entry.modelData?.buttonType ?? 0) === QsMenuButtonType.RadioButton ? 6.5 : 4
                        visible: (entry.modelData?.buttonType ?? 0) !== QsMenuButtonType.None
                        color: (entry.modelData?.checkState ?? Qt.Unchecked) === Qt.Checked ? Theme.accent : "transparent"
                        border.width: 1.4
                        border.color: (entry.modelData?.checkState ?? Qt.Unchecked) === Qt.Checked ? Theme.accent : Theme.muted
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(0, parent.width - x - (entry.expandable ? 18 : 0))
                        text: (entry.modelData?.text ?? "").replace(/_([A-Za-z])/, "$1")
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSizeSmall + 1
                    }
                }

                Icon {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    visible: entry.expandable
                    text: Theme.iconChevron
                    boxWidth: 12
                    font.pixelSize: 11
                    color: Theme.muted
                    rotation: entry.expanded ? 0 : -90

                    Behavior on rotation {
                        NumberAnimation {
                            duration: Theme.animNormal
                            easing.type: Theme.easing
                        }
                    }
                }

                MouseArea {
                    id: rowMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: entry.modelData?.enabled ?? true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (entry.expandable) {
                            entry.expanded = !entry.expanded;
                            return;
                        }

                        entry.modelData.triggered();
                        root.closeRequested();
                    }
                }
            }

            // Untermenü. Über `source` statt `sourceComponent`, weil QML eine
            // direkt verschachtelte MenuList als unendliche Rekursion ablehnt —
            // die URL wird erst zur Laufzeit aufgelöst.
            Loader {
                id: submenu

                x: 12
                width: parent.width - 12
                active: entry.expanded && entry.expandable
                visible: submenu.active
                source: submenu.active ? Qt.resolvedUrl("MenuList.qml") : ""

                onLoaded: {
                    submenu.item.depth = root.depth + 1;
                    submenu.item.rowWidth = root.rowWidth - 12;
                    submenu.item.handle = entry.modelData;
                    submenu.item.closeRequested.connect(root.closeRequested);
                }
            }
        }
    }
}
