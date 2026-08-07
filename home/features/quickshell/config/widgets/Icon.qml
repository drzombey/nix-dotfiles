import QtQuick
import QtQuick.Layouts
import qs

// Nerd-Font-Glyphe. Feste Box-Breite, damit Icons beim Wechsel (z.B.
// Lautstärke-Stufen) nicht die Breite der Zeile springen lassen.
// `implicitWidth` ist bei Text read-only, deshalb Breite doppelt setzen: `width`
// greift in Positionierern, `Layout.preferredWidth` in Layouts.
//
// Zentriert wird die *Ink-Fläche* der Glyphe, nicht der Textkasten: alle
// Nerd-Font-Symbole haben dieselbe Vorschubbreite (0,6 em), zeichnen aber je
// nach Glyphe bis zur vollen Schriftgröße breit und hängen dabei nach rechts
// über. Qt zentriert den Vorschub, das Symbol landet dadurch sichtbar zu weit
// rechts — beim Nix-Logo um gut 3 px.
//
// `tightBoundingRect` liefert die echten Ink-Grenzen (relativ zur Basislinie),
// `baselineOffset` deren Lage im Item. Daraus ergibt sich die Korrektur.
Text {
    id: root

    // Die Ink-Breite einer Glyphe geht bis zur Schriftgröße, deshalb hängt die
    // Kastenbreite daran und nicht an einem festen Wert.
    property real boxWidth: root.font.pixelSize + 3
    property bool centerInk: true

    font.family: Theme.iconFont
    font.pixelSize: Theme.iconSize
    color: Theme.text
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    width: root.boxWidth
    Layout.preferredWidth: root.boxWidth

    // Qts Distance-Field-Rendering (der Standard) zerlegt dünne Glyphen in
    // dieser Größe in blaue und orange Farbsäume — das Power-Symbol und das
    // Chevron im Tray-Menü waren so praktisch nicht mehr zu erkennen.
    // Gilt auch für gedrehte und skalierte Icons: NativeRendering bleibt dort
    // ebenfalls sauber, ein Zurückschalten ist nirgends nötig.
    renderType: Text.NativeRendering

    TextMetrics {
        id: metrics

        font: root.font
        text: root.text
    }

    // Auf ganze Pixel gerundet: eine Verschiebung um Bruchteile eines Pixels
    // zwingt Qt dazu, den gerasterten Text neu abzutasten. Bei Subpixel-
    // Antialiasing driften dabei die Farbkanäle auseinander — dünne Glyphen wie
    // das Power-Symbol werden dann zu farbigen Säumen statt zu einem Symbol.
    // Ein halbes Pixel Restversatz ist der bessere Handel.
    transform: Translate {
        // advanceWidth, nicht contentWidth: Qt setzt die Schreibmarke nach dem
        // Vorschub, und genau der weicht hier von der Ink-Breite ab.
        x: root.centerInk ? Math.round(metrics.advanceWidth / 2 - (metrics.tightBoundingRect.x + metrics.tightBoundingRect.width / 2)) : 0
        y: root.centerInk ? Math.round(root.height / 2 - (root.baselineOffset + metrics.tightBoundingRect.y + metrics.tightBoundingRect.height / 2)) : 0
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.animNormal
        }
    }
}
