import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs
import qs.widgets

// Icon + Titel des fokussierten Fensters. Verschwindet mitsamt Insel, wenn
// nichts fokussiert ist.
Island {
    id: root

    required property HyprlandMonitor monitor

    readonly property var toplevel: Hyprland.activeToplevel

    readonly property bool onThisMonitor: {
        if (!root.toplevel)
            return false;
        if (!root.monitor || !root.toplevel.monitor)
            return true;

        return root.toplevel.monitor.id === root.monitor.id;
    }

    readonly property string title: root.onThisMonitor ? (root.toplevel.title ?? "") : ""
    readonly property string appClass: root.onThisMonitor ? (root.toplevel.lastIpcObject?.class ?? "") : ""

    readonly property var entry: root.appClass === "" ? null : DesktopEntries.heuristicLookup(root.appClass)
    readonly property string iconSource: root.entry?.icon ? Quickshell.iconPath(root.entry.icon, true) : ""

    pad: Theme.islandPad + 4

    IconImage {
        Layout.alignment: Qt.AlignVCenter
        implicitSize: 17
        source: root.iconSource
        visible: root.title !== "" && root.iconSource !== ""
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        Layout.maximumWidth: 340
        text: root.title
        elide: Text.ElideRight
        color: Theme.subtext
        visible: root.title !== ""
    }
}
