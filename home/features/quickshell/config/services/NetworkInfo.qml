pragma Singleton

// Interfaces mit ihren IP-Adressen aus `ip -j addr`. Bewusst nicht über
// Quickshell.Networking: das kennt nur, was NetworkManager verwaltet — docker0,
// VPN- und Wireguard-Interfaces fehlen dort.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Wird nur abgefragt, solange ein Menü offen ist.
    property bool watching: false

    // [{ name: "wlp0s20f3", up: true, addresses: ["192.168.11.177/23"] }]
    property var interfaces: []

    function parse(json: string): void {
        let raw = [];

        try {
            raw = JSON.parse(json);
        } catch (e) {
            return;
        }

        const out = [];

        for (const dev of raw) {
            // scope "global" filtert Loopback (host) und IPv6-Link-Local (link)
            // heraus; übrig bleibt, was man tatsächlich anschreiben kann.
            const addresses = (dev.addr_info ?? []).filter(a => a.scope === "global").map(a => `${a.local}/${a.prefixlen}`);

            if (addresses.length === 0)
                continue;

            out.push({
                name: dev.ifname,
                up: dev.operstate === "UP",
                addresses: addresses
            });
        }

        // Aktive Interfaces zuerst, danach alphabetisch.
        out.sort((a, b) => a.up === b.up ? a.name.localeCompare(b.name) : (a.up ? -1 : 1));

        root.interfaces = out;
    }

    Process {
        id: proc

        command: ["ip", "-j", "addr"]

        stdout: StdioCollector {
            id: collector

            onStreamFinished: root.parse(collector.text)
        }
    }

    Timer {
        interval: 4000
        running: root.watching
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
