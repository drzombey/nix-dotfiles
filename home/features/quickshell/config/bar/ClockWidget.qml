import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets
import qs.popups

// Mittige Uhr; Klick öffnet den Kalender.
Island {
    id: root

    property var barWindow: null

    pad: Theme.islandPad + 1

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    BarItem {
        id: item

        active: calendar.open
        onActivated: calendar.open = !calendar.open

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Theme.formatDate(clock.date, "ddd d. MMM")
            color: Theme.subtext
            font.pixelSize: Theme.fontSizeSmall + 1
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 3
            implicitHeight: 3
            radius: 1.5
            color: Theme.accent
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: Theme.fontSize + 1
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
        }
    }

    CalendarPopup {
        id: calendar

        anchorItem: item
        barWindow: root.barWindow
    }
}
