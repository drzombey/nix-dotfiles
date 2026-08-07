# braavos: Quickshell-Bar

Waybar ist raus, die Bar ist jetzt eine eigene [Quickshell](https://quickshell.org)-
Konfiguration in QML. Quellcode: `home/features/quickshell/config`, Nix-Anbindung:
`home/features/quickshell/default.nix`.

## Aufbau

Die Bar ist transparent; sichtbar sind nur freischwebende „Inseln“.

| Bereich | Inhalt |
|---|---|
| links | Nix-Button (Launcher), Workspaces, Titel des fokussierten Fensters |
| mitte | Datum + Uhrzeit |
| rechts | Medien (MPRIS), CPU/RAM/Lautstärke/Akku, Tray, Power |

Bewusst **kein** eigenes Netzwerk-Icon: das zeigt nm-applet im Tray, zweimal
dasselbe Symbol in derselben Bar wäre Doppelung. Die IP-Adressen stehen
stattdessen in den Schnelleinstellungen.

## Bedienung

| Element | Aktion |
|---|---|
| Nix-Button | Links: `wofi`, Rechts: Terminal |
| Workspaces | Klick wechselt, Mausrad wechselt relativ |
| Uhr | Klick öffnet den Kalender |
| Medien | Links: Play/Pause, Rechts: nächster Track, Mausrad: Track wechseln |
| Status-Insel | Links: Schnelleinstellungen, Mitte: Stumm, Mausrad: Lautstärke |
| IP-Adresse | Klick kopiert sie ohne Präfixlänge in die Zwischenablage |
| Tray-Icon | Links: aktivieren, Rechts: Kontextmenü, Mitte: Sekundäraktion |
| Power | Klick öffnet Sperren / Bereitschaft / Abmelden / Neustart / Aus |

Popups schließen sich per Klick daneben (Hyprland-Focus-Grab) oder durch
erneuten Klick auf den auslösenden Button.

`SUPER+SHIFT+R` startet die Shell neu — nötig nach einem `nrs`, wenn sich nur
die QML-Dateien geändert haben und systemd den Service nicht selbst neu
gestartet hat.

## Struktur der Konfiguration

```
config/
  shell.qml        eine Bar pro Monitor (Variants über Quickshell.screens)
  Theme.qml        alle Farben, Abstände, Schriften, Icon-Codepoints
  widgets/         Bausteine: Island, BarItem, PopupSurface, Slider, …
  bar/             die Bar und ihre Module
  popups/          Kalender, Schnelleinstellungen, Sitzungsmenü, Tray-Menü
  services/        SysStats (CPU/RAM aus /proc), Battery und Brightness (sysfs),
                   NetworkInfo (ip -j addr)
```

Verzeichnisnamen sind gleichzeitig QML-Modulnamen: `bar/` wird zu `qs.bar`,
`widgets/` zu `qs.widgets`. Deshalb legt Home-Manager die Dateien mit
`recursive = true` als einzelne Symlinks in echten Verzeichnissen ab.

Farben und Maße stehen ausschließlich in `Theme.qml` — Module definieren keine
eigenen. Icons sind dort als Codepoints hinterlegt (`root.glyph(0xf057e)`), weil
die Nerd-Font-Glyphen in Unicode-Private-Use-Bereichen liegen und als Literale
Editoren und Diffs nicht zuverlässig überleben.

## Am Design arbeiten

Ohne Rebuild direkt aus dem Repository starten:

```bash
systemctl --user stop quickshell
qs -p ~/nix-dotfiles/home/features/quickshell/config
```

Quickshell lädt Dateiänderungen dabei selbst neu. Danach wieder auf die
verwaltete Instanz zurück:

```bash
systemctl --user start quickshell
```

Logs der laufenden Instanz: `journalctl --user -u quickshell -f`.

## Fallstricke

- **`font.families` gibt es in QML nicht.** Der `font`-Value-Type kennt nur
  `family`. Icons laufen deshalb über ein eigenes `Icon`-Element mit der
  Symbols-Nerd-Font, statt über Glyphen-Fallback in einem Text.
- **Nerd-Font-Glyphen sitzen nicht in ihrem Vorschub.** Alle Symbole haben
  dieselbe Vorschubbreite (0,6 em), zeichnen aber je nach Glyphe bis zur volle
  Schriftgröße breit und hängen nach rechts über. Qt zentriert den Vorschub —
  das Symbol landet dadurch zu weit rechts, beim Nix-Logo um gut 3 px. `Icon`
  rechnet die Korrektur über `TextMetrics.tightBoundingRect`,
  `advanceWidth` und `baselineOffset` aus und zentriert damit die echte
  Ink-Fläche. Wer ein Icon außerhalb von `Icon` als `Text` rendert, bekommt den
  Versatz zurück.
- **`Item.visibleChildren` hat kein Notify-Signal.** Eine Bindung darauf läuft
  genau einmal. `Island` misst deshalb die implizite Breite seines Layouts, um
  zu erkennen, ob es leer ist.
- **Der Focus-Grab braucht einen Frame Vorlauf.** Wird er im selben Frame
  aktiviert, in dem das Popup sichtbar wird, lehnt Hyprland ihn ab und
  `cleared` schließt das Popup sofort wieder.
- **Hyprland-Singletons laden asynchron.** `Hyprland.workspaces` & Co. sind
  direkt nach dem ersten Zugriff noch leer; in Bindungen ist das kein Problem,
  in einmaligem imperativem Code schon.
- **Qt findet die Zeitzonendatenbank auf NixOS nicht** ohne `TZDIR` — der
  systemd-Service setzt es auf `/etc/zoneinfo`. Die Locale übernimmt Qt
  ebenfalls nicht aus `LANG`, deshalb formatiert `Theme.formatDate` explizit
  mit `de_DE`.
- **Die Interface-Liste kommt aus `ip -j addr`, nicht aus Quickshell.Networking.**
  Letzteres kennt nur, was NetworkManager verwaltet — `docker0`, VPN- und
  Wireguard-Interfaces fehlen dort. `NetworkInfo` fragt nur ab, solange das
  Popup offen ist (`watching`), und filtert auf `scope: global`, was Loopback
  und IPv6-Link-Local aussortiert.
- **Der Akku kommt aus sysfs, nicht aus UPower.** Quickshell hat ein
  UPower-Modul, das braucht aber `services.upower.enable` — und ohne den Dienst
  bleibt die Anzeige stumm leer, ohne Fehlermeldung im Log. `services/Battery.qml`
  liest stattdessen `/sys/class/power_supply/BAT*` (`capacity`, `status` und je
  nach Treiber `charge_*`/`current_now` oder `energy_*`/`power_now`). Das läuft
  ohne Systemdienst. Die Energieprofile in den Schnelleinstellungen kommen
  weiterhin aus dem UPower-*Modul* von Quickshell, sprechen aber
  power-profiles-daemon — das ist ein anderer Dienst.
