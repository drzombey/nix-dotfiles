pragma Singleton

// Zentrale Design-Tokens. Alles Visuelle (Farben, Abstände, Icons) hängt hier
// dran — einzelne Module definieren keine eigenen Farben oder Größen.
import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Palette ──────────────────────────────────────────────────────────
    readonly property color base: "#0b0d13"

    // Die Inseln sind halbtransparent, damit der Desktop durchscheint.
    readonly property color islandBg: "#d2131722"
    readonly property color islandBorder: "#1cffffff"
    readonly property color popupBg: "#fb101420"
    readonly property color popupBorder: "#22ffffff"

    readonly property color hover: "#16ffffff"
    readonly property color press: "#26ffffff"
    readonly property color track: "#1affffff"

    readonly property color text: "#e6e9f2"
    readonly property color subtext: "#98a0b6"
    readonly property color muted: "#5b6478"

    readonly property color accent: "#a78bfa"
    readonly property color accentAlt: "#5fd3f3"
    readonly property color green: "#5cd68a"
    readonly property color yellow: "#f2ca6b"
    readonly property color orange: "#f0925b"
    readonly property color red: "#ef6f77"
    readonly property color pink: "#f27fb8"

    // ── Geometrie ────────────────────────────────────────────────────────
    readonly property int islandHeight: 30
    readonly property int islandRadius: 15
    readonly property int islandPad: 5
    readonly property int islandGap: 8

    // Luft zwischen Bildschirmrand und Insel; bestimmt die Höhe der Bar.
    readonly property int barGap: 6
    readonly property int barHeight: root.islandHeight + root.barGap * 2
    readonly property int barMarginSide: 10

    readonly property int itemHeight: 22
    readonly property int itemRadius: 11
    readonly property int itemPad: 9
    readonly property int itemGap: 3

    readonly property int popupRadius: 16
    readonly property int popupPad: 14

    // ── Typografie ───────────────────────────────────────────────────────
    // QMLs font-Value-Type kennt nur `family`, nicht `families` — Icons laufen
    // deshalb über eine eigene Schriftart statt über Fallback in einem Text.
    readonly property string textFont: "Inter"
    readonly property string iconFont: "Symbols Nerd Font"
    // Für IP-Adressen: gleiche Ziffernbreite, damit die Spalte ruhig steht.
    readonly property string monoFont: "JetBrainsMono Nerd Font"

    readonly property int fontSize: 12
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeLarge: 14
    readonly property int iconSize: 14
    readonly property int iconSizeLarge: 17

    // ── Animation ────────────────────────────────────────────────────────
    readonly property int animFast: 120
    readonly property int animNormal: 200
    readonly property int animSlow: 340
    readonly property int easing: Easing.OutQuint

    // ── Icons (Nerd Font) ────────────────────────────────────────────────
    // Als Codepoints statt als Literale: die Glyphen liegen in Unicode-
    // Private-Use-Bereichen und überleben Editoren und Diffs nicht zuverlässig.
    function glyph(code: int): string {
        return String.fromCodePoint(code);
    }

    readonly property string iconNix: root.glyph(0xf313)          // nf-linux-nixos

    readonly property string iconVolHigh: root.glyph(0xf057e)
    readonly property string iconVolMed: root.glyph(0xf0580)
    readonly property string iconVolLow: root.glyph(0xf057f)
    readonly property string iconVolMute: root.glyph(0xf075f)

    readonly property string iconWifi4: root.glyph(0xf0928)
    readonly property string iconWifi3: root.glyph(0xf0925)
    readonly property string iconWifi2: root.glyph(0xf0922)
    readonly property string iconWifi1: root.glyph(0xf091f)
    readonly property string iconWifiOff: root.glyph(0xf092d)
    readonly property string iconEthernet: root.glyph(0xf0200)

    readonly property string iconBolt: root.glyph(0xf0241)        // flash

    readonly property string iconPower: root.glyph(0xf0425)
    readonly property string iconLock: root.glyph(0xf033e)
    readonly property string iconLogout: root.glyph(0xf0343)
    readonly property string iconRestart: root.glyph(0xf0709)
    readonly property string iconSleep: root.glyph(0xf0904)

    readonly property string iconPlay: root.glyph(0xf040a)
    readonly property string iconPause: root.glyph(0xf03e4)

    readonly property string iconCpu: root.glyph(0xf0ee0)
    readonly property string iconRam: root.glyph(0xf035b)
    readonly property string iconBrightness: root.glyph(0xf00e0)
    readonly property string iconPerf: root.glyph(0xf04c5)        // speedometer
    readonly property string iconBalanced: root.glyph(0xf0f85)
    readonly property string iconSaver: root.glyph(0xf0f86)
    readonly property string iconChevron: root.glyph(0xf0140)

    // ── Verhalten ────────────────────────────────────────────────────────
    // Workspaces, die immer sichtbar sind, auch wenn leer.
    readonly property int pinnedWorkspaces: 5
    readonly property list<string> launcher: ["wofi", "--show", "drun"]
    readonly property list<string> terminal: ["ghostty"]

    // ── Datum/Zeit ───────────────────────────────────────────────────────
    // Qt übernimmt LANG hier nicht zuverlässig, deshalb explizit.
    readonly property var locale: Qt.locale("de_DE")

    function formatDate(when: date, format: string): string {
        return when.toLocaleString(root.locale, format);
    }
}
