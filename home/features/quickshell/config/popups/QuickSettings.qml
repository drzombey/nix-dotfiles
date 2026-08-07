import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
// Nur für PowerProfiles: das spricht power-profiles-daemon, nicht den
// UPower-Dienst. Der Akkustand kommt aus qs.services (sysfs).
import Quickshell.Services.UPower
import qs
import qs.services
import qs.widgets

// Schnelleinstellungen: Lautstärke, Helligkeit, Energieprofil, CPU/RAM/Akku und
// die IP-Adressen der Interfaces.
PopupSurface {
    id: root

    // Die Interface-Liste wird nur abgefragt, solange das Popup offen ist.
    onOpenChanged: NetworkInfo.watching = root.open

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false

    surfaceWidth: 330
    surfaceHeight: col.implicitHeight + Theme.popupPad * 2

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    ColumnLayout {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.popupPad
        spacing: 12

        // ── Lautstärke ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            GlyphButton {
                glyph: {
                    if (root.muted || root.volume < 0.01)
                        return Theme.iconVolMute;
                    if (root.volume < 0.5)
                        return Theme.iconVolMed;

                    return Theme.iconVolHigh;
                }
                accented: !root.muted
                onTriggered: {
                    if (root.sink?.audio)
                        root.sink.audio.muted = !root.sink.audio.muted;
                }
            }

            Slider {
                Layout.fillWidth: true
                value: root.muted ? 0 : root.volume
                fillColor: Theme.accent
                fillColorAlt: Theme.pink
                onMoved: v => {
                    if (root.sink?.audio) {
                        root.sink.audio.muted = false;
                        root.sink.audio.volume = v;
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(root.volume * 100)}%`
                color: Theme.subtext
                font.pixelSize: Theme.fontSizeSmall + 1
            }
        }

        // ── Helligkeit ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: Brightness.available

            GlyphButton {
                glyph: Theme.iconBrightness
                accented: true
                onTriggered: Brightness.setValue(Brightness.value > 0.5 ? 0.2 : 1)
            }

            Slider {
                Layout.fillWidth: true
                value: Brightness.value
                fillColor: Theme.yellow
                fillColorAlt: Theme.orange
                onMoved: v => Brightness.setValue(v)
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(Brightness.value * 100)}%`
                color: Theme.subtext
                font.pixelSize: Theme.fontSizeSmall + 1
            }
        }

        Divider {}

        // ── Energieprofil ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: PowerProfiles.hasPerformanceProfile || PowerProfiles.profile !== PowerProfile.Balanced

            Chip {
                label: "Sparen"
                glyph: Theme.iconSaver
                selected: PowerProfiles.profile === PowerProfile.PowerSaver
                onTriggered: PowerProfiles.profile = PowerProfile.PowerSaver
            }

            Chip {
                label: "Balance"
                glyph: Theme.iconBalanced
                selected: PowerProfiles.profile === PowerProfile.Balanced
                onTriggered: PowerProfiles.profile = PowerProfile.Balanced
            }

            Chip {
                label: "Leistung"
                glyph: Theme.iconPerf
                enabled: PowerProfiles.hasPerformanceProfile
                selected: PowerProfiles.profile === PowerProfile.Performance
                onTriggered: PowerProfiles.profile = PowerProfile.Performance
            }
        }

        Divider {}

        // ── Auslastung ───────────────────────────────────────────────────
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 16
            rowSpacing: 8

            StatLine {
                glyph: Theme.iconCpu
                label: "CPU"
                detail: `${Math.round(SysStats.cpu * 100)} %`
                ratio: SysStats.cpu
                barColor: Theme.accent
            }

            StatLine {
                glyph: Theme.iconRam
                label: "RAM"
                detail: `${SysStats.memUsedGiB.toFixed(1)} / ${SysStats.memTotalGiB.toFixed(1)} GiB`
                ratio: SysStats.mem
                barColor: Theme.accentAlt
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: Battery.present
            color: Theme.muted
            font.pixelSize: Theme.fontSizeSmall
            text: {
                if (!Battery.present)
                    return "";

                const pct = Math.round(Battery.percent);
                const remaining = Battery.secondsRemaining;

                if (Battery.full)
                    return `Akku ${pct} % · vollgeladen`;

                if (Battery.charging)
                    return remaining > 0 ? `Akku ${pct} % · voll in ${root.formatTime(remaining)}` : `Akku ${pct} % · lädt`;

                return remaining > 0 ? `Akku ${pct} % · noch ${root.formatTime(remaining)}` : `Akku ${pct} %`;
            }
        }

        Divider {}

        // ── Netzwerk ─────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: "Netzwerk"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.muted
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: "Klick kopiert"
                    font.pixelSize: Theme.fontSizeSmall - 1
                    color: Theme.muted
                    opacity: 0.7
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: NetworkInfo.interfaces.length === 0
                text: "keine Adressen"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.muted
            }

            Repeater {
                model: NetworkInfo.interfaces

                RowLayout {
                    id: ifaceRow

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: ifaceRow.modelData.up ? Theme.green : Theme.muted
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        text: ifaceRow.modelData.name
                        font.pixelSize: Theme.fontSizeSmall
                        color: ifaceRow.modelData.up ? Theme.subtext : Theme.muted
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Repeater {
                            model: ifaceRow.modelData.addresses

                            Rectangle {
                                id: addrChip

                                required property string modelData

                                Layout.alignment: Qt.AlignRight
                                implicitWidth: addrLabel.implicitWidth + 10
                                implicitHeight: addrLabel.implicitHeight + 4
                                radius: 5
                                color: addrMouse.containsMouse ? Theme.hover : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.animFast
                                    }
                                }

                                StyledText {
                                    id: addrLabel

                                    anchors.centerIn: parent
                                    text: addrChip.modelData
                                    font.family: Theme.monoFont
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.letterSpacing: 0
                                    color: ifaceRow.modelData.up ? Theme.text : Theme.muted
                                }

                                MouseArea {
                                    id: addrMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    // Ohne Präfixlänge — was man in ein Eingabefeld tippt.
                                    onClicked: Quickshell.clipboardText = addrChip.modelData.split("/")[0]
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function formatTime(seconds: real): string {
        const total = Math.round(seconds / 60);
        const h = Math.floor(total / 60);
        const m = total % 60;

        return h > 0 ? `${h} h ${m} min` : `${m} min`;
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.popupBorder
    }

    component GlyphButton: Rectangle {
        id: gbtn

        property string glyph: ""
        property bool accented: false

        signal triggered

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 28
        implicitHeight: 28
        radius: 14
        color: gbtnMouse.containsMouse ? Theme.hover : Theme.track

        Behavior on color {
            ColorAnimation {
                duration: Theme.animFast
            }
        }

        Icon {
            anchors.centerIn: parent
            text: gbtn.glyph
            color: gbtn.accented ? Theme.text : Theme.muted
            font.pixelSize: Theme.iconSize
        }

        MouseArea {
            id: gbtnMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: gbtn.triggered()
        }
    }

    component Chip: Rectangle {
        id: chip

        property string label: ""
        property string glyph: ""
        property bool selected: false

        signal triggered

        Layout.fillWidth: true
        implicitHeight: 30
        radius: 10
        opacity: chip.enabled ? 1 : 0.4
        color: chip.selected ? Theme.accent : (chipMouse.containsMouse ? Theme.hover : Theme.track)

        Behavior on color {
            ColorAnimation {
                duration: Theme.animFast
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 5

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.glyph
                boxWidth: Theme.iconSize
                color: chip.selected ? Theme.base : Theme.subtext
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.label
                font.pixelSize: Theme.fontSizeSmall
                font.weight: chip.selected ? Font.DemiBold : Font.Medium
                color: chip.selected ? Theme.base : Theme.subtext
            }
        }

        MouseArea {
            id: chipMouse

            anchors.fill: parent
            enabled: chip.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.triggered()
        }
    }

    component StatLine: ColumnLayout {
        id: stat

        property string glyph: ""
        property string label: ""
        property string detail: ""
        property real ratio: 0
        property color barColor: Theme.accent

        Layout.fillWidth: true
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Icon {
                Layout.alignment: Qt.AlignVCenter
                text: stat.glyph
                boxWidth: Theme.iconSize
                color: stat.barColor
                font.pixelSize: Theme.fontSizeSmall + 2
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: stat.label
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.subtext
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: stat.detail
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.text
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 5
            radius: 2.5
            color: Theme.track

            Rectangle {
                width: Math.max(height, parent.width * Math.max(0, Math.min(1, stat.ratio)))
                height: parent.height
                radius: parent.radius
                color: stat.barColor

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animSlow
                        easing.type: Theme.easing
                    }
                }
            }
        }
    }
}
