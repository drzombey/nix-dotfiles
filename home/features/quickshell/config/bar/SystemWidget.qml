import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.services
import qs.widgets
import qs.popups

// Status-Insel: CPU/RAM-Balken, Lautstärke, Akku.
// Linksklick öffnet die Schnelleinstellungen, Mausrad regelt die Lautstärke,
// Mittelklick schaltet stumm.
//
// Kein Netzwerk-Icon: das zeigt nm-applet im Tray, zweimal dasselbe Symbol in
// derselben Bar wäre Doppelung. Die IP-Adressen stehen in den
// Schnelleinstellungen.
Island {
    id: root

    property var barWindow: null

    // ── Audio ────────────────────────────────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false

    readonly property string volumeIcon: {
        if (root.muted || root.volume < 0.01)
            return Theme.iconVolMute;
        if (root.volume < 0.34)
            return Theme.iconVolLow;
        if (root.volume < 0.67)
            return Theme.iconVolMed;

        return Theme.iconVolHigh;
    }

    function setVolume(v: real): void {
        if (root.sink?.audio)
            root.sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute(): void {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    BarItem {
        id: item

        active: quickSettings.open
        spacing: 8

        onActivated: quickSettings.open = !quickSettings.open
        onMiddleActivated: root.toggleMute()
        onScrolled: delta => root.setVolume(root.volume + (delta > 0 ? 0.05 : -0.05))

        Column {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Meter {
                value: SysStats.cpu
                fillColor: SysStats.cpu > 0.85 ? Theme.red : (SysStats.cpu > 0.6 ? Theme.orange : Theme.accent)
            }

            Meter {
                value: SysStats.mem
                fillColor: SysStats.mem > 0.9 ? Theme.red : Theme.accentAlt
            }
        }

        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Icon {
                text: root.volumeIcon
                color: root.muted ? Theme.muted : Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Math.round(root.volume * 100)}%`
                color: root.muted ? Theme.muted : Theme.subtext
                font.pixelSize: Theme.fontSizeSmall + 1
            }
        }

        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 5
            visible: battery.present

            BatteryIndicator {
                id: battery

                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Math.round(battery.level * 100)}%`
                color: battery.level <= 0.15 && !battery.charging ? Theme.red : Theme.subtext
                font.pixelSize: Theme.fontSizeSmall + 1
            }
        }
    }

    QuickSettings {
        id: quickSettings

        anchorItem: item
        barWindow: root.barWindow
    }
}
