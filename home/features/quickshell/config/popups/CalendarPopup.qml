import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.widgets

// Monatskalender. `viewDate` ist der angezeigte Monat und wird beim Öffnen
// wieder auf heute zurückgesetzt.
PopupSurface {
    id: root

    // Über die Uhr gebunden, damit die Heute-Markierung über Mitternacht wandert.
    readonly property date today: clock.date

    property int viewYear: 0
    property int viewMonth: 0

    readonly property int cell: 34
    readonly property int cols: 7

    surfaceWidth: root.cols * root.cell + Theme.popupPad * 2
    surfaceHeight: Theme.popupPad * 2 + header.height + 12 + weekdays.height + 2 + grid.height

    onOpenChanged: {
        if (root.open)
            root.resetView();
    }

    function resetView(): void {
        root.viewYear = root.today.getFullYear();
        root.viewMonth = root.today.getMonth();
    }

    function shiftMonth(delta: int): void {
        const d = new Date(root.viewYear, root.viewMonth + delta, 1);
        root.viewYear = d.getFullYear();
        root.viewMonth = d.getMonth();
    }

    // 6 Wochen à 7 Tage, beginnend am Montag der Woche des Monatsersten.
    readonly property var cells: {
        const first = new Date(root.viewYear, root.viewMonth, 1);
        const offset = (first.getDay() + 6) % 7;
        const out = [];

        for (let i = 0; i < 42; i++) {
            const d = new Date(root.viewYear, root.viewMonth, 1 - offset + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === root.viewMonth,
                isToday: d.getFullYear() === root.today.getFullYear() && d.getMonth() === root.today.getMonth() && d.getDate() === root.today.getDate()
            });
        }

        return out;
    }

    Component.onCompleted: root.resetView()

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Item {
        anchors.fill: parent
        anchors.margins: Theme.popupPad

        RowLayout {
            id: header

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28
            spacing: 4

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: Theme.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                }

                StyledText {
                    text: Theme.formatDate(root.today, "dddd, d. MMMM")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.accent
                }
            }

            NavButton {
                glyph: "‹"
                onTriggered: root.shiftMonth(-1)
            }

            NavButton {
                glyph: "•"
                onTriggered: root.resetView()
            }

            NavButton {
                glyph: "›"
                onTriggered: root.shiftMonth(1)
            }
        }

        Row {
            id: weekdays

            anchors.top: header.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            height: 20

            Repeater {
                model: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

                StyledText {
                    required property string modelData

                    width: root.cell
                    height: 20
                    text: modelData
                    color: Theme.muted
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Grid {
            id: grid

            anchors.top: weekdays.bottom
            anchors.topMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            columns: root.cols
            rows: 6

            Repeater {
                model: root.cells

                Item {
                    id: dayCell

                    required property var modelData

                    width: root.cell
                    height: root.cell - 2

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: 14
                        color: dayCell.modelData.isToday ? Theme.accent : (dayHover.containsMouse ? Theme.hover : "transparent")

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                            }
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: dayCell.modelData.day
                        font.pixelSize: Theme.fontSize
                        font.weight: dayCell.modelData.isToday ? Font.Bold : Font.Normal
                        color: dayCell.modelData.isToday ? Theme.base : (dayCell.modelData.inMonth ? Theme.text : Theme.muted)
                    }

                    MouseArea {
                        id: dayHover

                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }
    }

    component NavButton: Rectangle {
        id: nav

        property string glyph: ""

        signal triggered

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 24
        implicitHeight: 24
        radius: 12
        color: navMouse.containsMouse ? Theme.hover : "transparent"

        StyledText {
            anchors.centerIn: parent
            text: nav.glyph
            color: Theme.subtext
            font.pixelSize: Theme.fontSizeLarge
        }

        MouseArea {
            id: navMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.triggered()
        }
    }
}
