import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.widgets

// MPRIS-Anzeige. Klick pausiert, Rechtsklick springt weiter, Scrollen wechselt
// den Track. Ohne Player kollabiert die ganze Insel.
Island {
    id: root

    property var barWindow: null

    // Der spielende Player gewinnt, sonst der erste bekannte.
    readonly property var player: {
        const players = Mpris.players.values;

        for (const p of players)
            if (p.isPlaying)
                return p;

        return players.length > 0 ? players[0] : null;
    }

    readonly property bool playing: root.player?.isPlaying ?? false

    readonly property string label: {
        if (!root.player)
            return "";

        const parts = [root.player.trackTitle, root.player.trackArtist].filter(s => !!s);
        return parts.join("  ·  ");
    }

    pad: Theme.islandPad + 1

    BarItem {
        visible: !!root.player
        pad: Theme.itemPad - 2

        onActivated: {
            if (root.player?.canTogglePlaying)
                root.player.togglePlaying();
        }

        onSecondaryActivated: {
            if (root.player?.canGoNext)
                root.player.next();
        }

        onScrolled: delta => {
            if (delta > 0) {
                if (root.player?.canGoNext)
                    root.player.next();
            } else if (root.player?.canGoPrevious) {
                root.player.previous();
            }
        }

        // Kleiner Equalizer, der nur läuft, während wirklich gespielt wird.
        Row {
            Layout.alignment: Qt.AlignVCenter
            height: 14
            spacing: 2
            visible: root.playing

            Repeater {
                model: [0, 130, 260]

                Item {
                    required property int modelData

                    width: 3
                    height: 14

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: 3
                        height: 4
                        radius: 1.5
                        color: Theme.accentAlt

                        SequentialAnimation on height {
                            running: root.playing
                            loops: Animation.Infinite

                            PauseAnimation {
                                duration: modelData
                            }

                            NumberAnimation {
                                to: 14
                                duration: 380
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: 4
                                duration: 380
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        Icon {
            Layout.alignment: Qt.AlignVCenter
            text: root.playing ? Theme.iconPause : Theme.iconPlay
            color: Theme.accentAlt
            visible: !root.playing
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 220
            text: root.label
            elide: Text.ElideRight
            color: Theme.text
            font.pixelSize: Theme.fontSizeSmall + 1
        }
    }
}
