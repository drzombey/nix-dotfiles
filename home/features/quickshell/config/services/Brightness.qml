pragma Singleton

// Displayhelligkeit über sysfs lesen, über brightnessctl setzen.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string device: ""
    property real max: 0
    property real raw: 0

    readonly property bool available: root.device !== "" && root.max > 1
    readonly property real value: root.max > 0 ? root.raw / root.max : 0

    function setValue(v: real): void {
        if (!root.available)
            return;

        // Nie ganz auf 0 — ein schwarzes Display ist keine Einstellung, die man
        // per Slider zurücknehmen kann.
        const pct = Math.round(Math.max(0.02, Math.min(1, v)) * 100);
        // Optimistisch setzen; der Timer liest den echten Wert gleich nach.
        root.raw = root.max * pct / 100;
        // execDetached statt eines Process-Objekts: beim Ziehen am Slider
        // kommen die Aufrufe schneller als ein einzelner Prozess fertig wird.
        Quickshell.execDetached(["brightnessctl", "-q", "-d", root.device, "set", `${pct}%`]);
    }

    Process {
        id: detectProc

        running: true
        command: ["sh", "-c", "ls -1 /sys/class/backlight/ 2>/dev/null | head -n1"]

        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        id: maxFile

        path: root.device === "" ? "" : `/sys/class/backlight/${root.device}/max_brightness`
        onLoaded: root.max = parseFloat(maxFile.text())
    }

    FileView {
        id: curFile

        path: root.device === "" ? "" : `/sys/class/backlight/${root.device}/brightness`
        onLoaded: root.raw = parseFloat(curFile.text())
    }

    Timer {
        interval: 2000
        running: root.device !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: curFile.reload()
    }
}
