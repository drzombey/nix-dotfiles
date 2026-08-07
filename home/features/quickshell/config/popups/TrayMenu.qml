import QtQuick
import Quickshell
import qs
import qs.widgets

// Kontextmenü eines Tray-Icons.
PopupSurface {
    id: root

    property var handle: null

    surfaceWidth: 244
    surfaceHeight: Math.max(40, list.implicitHeight + 12)

    MenuList {
        id: list

        x: 6
        y: 6
        rowWidth: root.surfaceWidth - 12
        handle: root.open ? root.handle : null
        onCloseRequested: root.open = false
    }
}
