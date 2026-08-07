pragma Singleton

// CPU-Last und Speicherverbrauch direkt aus /proc — kein Subprozess pro Tick.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // 0..1
    property real cpu: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0

    readonly property real mem: root.memTotalGiB > 0 ? root.memUsedGiB / root.memTotalGiB : 0

    // Letzte Jiffy-Zählerstände; CPU-Last ist die Differenz zweier Messungen.
    property real prevTotal: 0
    property real prevIdle: 0

    function parseStat(text: string): void {
        const line = text.split("\n", 1)[0];
        if (!line.startsWith("cpu "))
            return;

        const f = line.split(/\s+/).slice(1).map(parseFloat);
        if (f.length < 5)
            return;

        // idle + iowait gelten als untätig
        const idle = f[3] + f[4];
        let total = 0;
        for (const v of f)
            total += v;

        const dTotal = total - root.prevTotal;
        const dIdle = idle - root.prevIdle;

        if (root.prevTotal > 0 && dTotal > 0)
            root.cpu = Math.max(0, Math.min(1, 1 - dIdle / dTotal));

        root.prevTotal = total;
        root.prevIdle = idle;
    }

    function parseMem(text: string): void {
        let total = 0;
        let available = 0;

        for (const line of text.split("\n")) {
            if (line.startsWith("MemTotal:"))
                total = parseFloat(line.split(/\s+/)[1]);
            else if (line.startsWith("MemAvailable:"))
                available = parseFloat(line.split(/\s+/)[1]);

            if (total > 0 && available > 0)
                break;
        }

        if (total <= 0)
            return;

        root.memTotalGiB = total / 1048576;
        root.memUsedGiB = (total - available) / 1048576;
    }

    FileView {
        id: statFile

        path: "/proc/stat"
        onLoaded: root.parseStat(statFile.text())
    }

    FileView {
        id: memFile

        path: "/proc/meminfo"
        onLoaded: root.parseMem(memFile.text())
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            statFile.reload();
            memFile.reload();
        }
    }
}
