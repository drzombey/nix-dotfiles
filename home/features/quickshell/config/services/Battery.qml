pragma Singleton

// Akkustatus direkt aus sysfs statt über UPower: das braucht keinen laufenden
// Systemdienst und funktioniert damit auch, wenn services.upower aus ist.
//
// Je nach Treiber liegen die Werte als Ladung (charge_*, µAh/µA) oder als
// Energie (energy_*, µWh/µW) vor — beides wird unterstützt, die Einheit wird
// beim Start einmal erkannt.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string device: ""
    property string unit: "charge"

    property real percent: 0
    property string status: "Unknown"
    property real chargeNow: 0
    property real chargeFull: 0
    property real rate: 0

    readonly property bool present: root.device !== ""
    readonly property real level: Math.max(0, Math.min(1, root.percent / 100))
    readonly property bool charging: root.status === "Charging"
    readonly property bool full: root.status === "Full"

    readonly property string base: root.device === "" ? "" : `/sys/class/power_supply/${root.device}`

    // Restlaufzeit in Sekunden; 0 heißt „nicht bestimmbar". Bei fast null
    // Stromfluss (voll geladen, Netzteil dran) ergibt die Rechnung keinen Sinn.
    readonly property real secondsRemaining: {
        if (root.rate < 1000 || root.chargeFull <= 0)
            return 0;

        const missing = root.charging ? root.chargeFull - root.chargeNow : root.chargeNow;
        if (missing <= 0)
            return 0;

        return missing / root.rate * 3600;
    }

    Process {
        running: true
        command: ["sh", "-c", "d=$(ls -1d /sys/class/power_supply/BAT* 2>/dev/null | head -n1); [ -n \"$d\" ] || exit 0; basename \"$d\"; [ -f \"$d/energy_now\" ] && echo energy || echo charge"]

        stdout: StdioCollector {
            id: detect

            onStreamFinished: {
                const lines = detect.text.trim().split("\n");
                if (lines.length < 2 || lines[0] === "")
                    return;

                root.device = lines[0];
                root.unit = lines[1];
            }
        }
    }

    FileView {
        id: capacityFile

        path: root.base === "" ? "" : `${root.base}/capacity`
        onLoaded: root.percent = parseFloat(capacityFile.text())
    }

    FileView {
        id: statusFile

        path: root.base === "" ? "" : `${root.base}/status`
        onLoaded: root.status = statusFile.text().trim()
    }

    FileView {
        id: nowFile

        path: root.base === "" ? "" : `${root.base}/${root.unit}_now`
        onLoaded: root.chargeNow = parseFloat(nowFile.text())
    }

    FileView {
        id: fullFile

        path: root.base === "" ? "" : `${root.base}/${root.unit}_full`
        onLoaded: root.chargeFull = parseFloat(fullFile.text())
    }

    FileView {
        id: rateFile

        path: root.base === "" ? "" : `${root.base}/${root.unit === "energy" ? "power" : "current"}_now`
        onLoaded: root.rate = parseFloat(rateFile.text())
    }

    Timer {
        interval: 10000
        running: root.present
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            capacityFile.reload();
            statusFile.reload();
            nowFile.reload();
            fullFile.reload();
            rateFile.reload();
        }
    }
}
