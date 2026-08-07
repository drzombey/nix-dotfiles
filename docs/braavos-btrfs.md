# braavos: ext4 → btrfs (Neuinstall mit disko)

Von ext4 nach btrfs gibt es keinen sinnvollen In-Place-Weg (`btrfs-convert`
hinterlässt ein fragmentiertes FS ohne Subvolume-Layout). Also: Backup,
Neuinstall von der ISO, Restore.

> Diese Datei liegt beim Backup zusätzlich als `BTRFS-ANLEITUNG.md` auf dem
> Ventoy-Stick — auf der ISO lesbar mit
> `less /run/media/*/Ventoy/BTRFS-ANLEITUNG.md` bzw. nach dem Mounten des
> Sticks. Sonst braucht man die Anleitung, um an die Anleitung zu kommen.

Layout danach — siehe `systems/braavos/disko.nix`:

| Partition | Größe | Inhalt |
|---|---|---|
| `p1` ESP | 1 G | vfat → `/boot` |
| `p2` | 68 G | LUKS `cryptswap` → swap (`resumeDevice`, Hibernation-fähig) |
| `p3` | Rest | LUKS `cryptroot` → btrfs, Label `braavos` |

Subvolumes: `/root`→`/`, `/home`→`/home`, `/nix`→`/nix`,
`/home/.snapshots`, `/snapshots`→`/.snapshots` — alle mit `compress=zstd,noatime`.

---

## 0. Config committen und pushen

Die ISO holt das Flake von GitHub — was nicht gepusht ist, existiert dort nicht.
Das Repo `github.com/drzombey/nix-dotfiles` ist öffentlich, der Clone von der
ISO braucht also keine Credentials (der 1Password-SSH-Agent läuft dort nicht).

```bash
cd /home/tim/nix-dotfiles
git add -A && git commit -m "braavos: btrfs via disko"
git push
```

## 1. Backup (vorher! nichts davon ist wiederherstellbar)

`sops`/age ist auf braavos **nicht** im Spiel — `./features/secrets` wird nur von
`home/default.nix` (valyria/macOS) importiert, `home/braavos.nix` nicht. Es gibt
hier auch keinen `~/.config/sops/age/keys.txt`. Also nichts zu retten.

`/home/tim` ist ~4,2 G, das passt als Tarball auf den Ventoy-Stick. Tarball statt
`rsync`, weil die Ventoy-Datenpartition exFAT ist und Unix-Rechte/Symlinks nicht
speichern kann — im Archiv bleiben sie erhalten:

```bash
sudo mkdir -p /mnt/ventoy
sudo mount /dev/disk/by-label/Ventoy /mnt/ventoy   # per Label, /dev/sdX verrutscht
VENTOY=/mnt/ventoy
STAMP=$(date +%F)

sudo tar -C /home --exclude='tim/.cache' --exclude='tim/.local/share/Trash' \
  -czf "$VENTOY/home-tim-$STAMP.tar.gz" tim
sudo tar -C /etc/NetworkManager \
  -czf "$VENTOY/nm-connections-$STAMP.tar.gz" system-connections

# Anleitung mit auf den Stick — die Schritte zum Clonen stehen ja hier drin
sudo cp /home/tim/nix-dotfiles/docs/braavos-btrfs.md "$VENTOY/BTRFS-ANLEITUNG.md"
```

Enthalten ist damit auch `~/.ssh`, der GNOME-Keyring
(`~/.local/share/keyrings/`) und `~/.claude/`. `~/.cache` ist bewusst draußen
(regenerierbar).

Separat, falls dir Container-State wichtig ist (Docker-Volumes liegen außerhalb
von `/home`):

```bash
sudo tar -C /var/lib -czf "$VENTOY/docker-$STAMP.tar.gz" docker
```

Und: offene Commits im privaten nvim-Config-Repo pushen.

**Backup verifizieren, bevor Schritt 2 läuft** — `-tzf > /dev/null`
dekomprimiert das ganze Archiv und findet damit auch Abbrüche mitten drin:

```bash
tar -tzf "$VENTOY/home-tim-$STAMP.tar.gz" > /dev/null && echo OK
sync && sudo umount /mnt/ventoy
```

## 2. Von der Ventoy-ISO booten

Auf dem Stick liegt `nixos-graphical-26.05.…iso`. Die bootet in einen Desktop
mit dem grafischen Calamares-Installer — **den nicht benutzen**, der kennt weder
disko noch dein Flake. Stattdessen ein Terminal öffnen.

Verifiziert für genau diese ISO-Revision: `installation-device.nix` setzt dort
kein `experimental-features`, Flakes sind also **nicht** aktiv. Die
`extra-experimental-features`-Flags unten sind daher nötig.

WLAN/LAN verbinden (`nmtui`), dann:

```bash
sudo -i
nix-shell -p git --run 'git clone https://github.com/drzombey/nix-dotfiles /tmp/dotfiles'
```

Auf den Installer-ISOs sind Flakes **nicht** standardmäßig aktiv, deshalb hängt
an allen `nix`-Aufrufen unten `--extra-experimental-features "nix-command flakes"`.
Falls deine ISO neu genug ist, ist das Flag einfach wirkungslos.

## 3. Platte partitionieren (ZERSTÖRT ALLE DATEN)

```bash
nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --flake /tmp/dotfiles#braavos
```

Es wird **zweimal** nach einer Passphrase gefragt (einmal `cryptswap`, einmal
`cryptroot`), jeweils mit Bestätigung. **Dieselbe Passphrase für beide
eingeben** — systemd-initrd cached die erste Eingabe im Kernel-Keyring und
probiert sie beim zweiten Container automatisch, sonst musst du beim Booten
dauerhaft zweimal tippen.

Danach kontrollieren:

```bash
mount | grep /mnt          # /mnt, /mnt/home, /mnt/nix, /mnt/boot, .snapshots
btrfs subvolume list /mnt
```

## 4. Installieren

```bash
nixos-install --flake /tmp/dotfiles#braavos \
  --option extra-experimental-features "nix-command flakes"
```

Am Ende wird das **root**-Passwort gesetzt. Das Passwort für `tim` fehlt dann
noch (`mutableUsers` ist an, die Config setzt kein `hashedPassword`):

```bash
nixos-enter --root /mnt -c 'passwd tim'
```

Reboot, USB-Stick ziehen.

## 5. Restore

Nach dem ersten Login (Hyprland läuft, weil die Config schon vollständig
installiert ist) den Stick einstecken:

```bash
sudo mkdir -p /mnt/ventoy
sudo mount /dev/disk/by-label/Ventoy /mnt/ventoy
VENTOY=/mnt/ventoy
ls "$VENTOY"/home-tim-*.tar.gz      # exakten Dateinamen ablesen
STAMP=2026-08-07                     # ← auf das Datum des Backups setzen

# Home zurück. --overwrite, weil nixos-install/home-manager schon Dateien
# angelegt hat (z.B. .config/fish, .bashrc)
sudo tar -C /home -xzf "$VENTOY/home-tim-$STAMP.tar.gz" --overwrite
sudo chown -R tim:users /home/tim

# WLAN
sudo tar -C /etc/NetworkManager -xzf "$VENTOY/nm-connections-$STAMP.tar.gz" --overwrite
sudo systemctl restart NetworkManager

sync && sudo umount /mnt/ventoy
```

Danach einmal ab- und wieder anmelden, damit home-manager auf dem
zurückgespielten Home aufsetzt, dann `nrs` (= `sudo nixos-rebuild switch --flake
/home/tim/nix-dotfiles`).

## 6. Verifizieren

```bash
findmnt -t btrfs                  # Subvolumes gemountet?
sudo btrfs subvolume list /       # root, home, home/.snapshots, nix, snapshots
sudo compsize /home /nix          # Compression greift?
swapon --show                     # 68G aktiv
systemctl list-timers | grep -E 'snapper|btrfs'
sudo snapper -c home list         # nach der ersten Stunde nicht mehr leer
```

Hibernation testen (optional, erst wenn der Rest läuft):

```bash
systemctl hibernate
```

---

## Danach: was btrfs dir jetzt gibt

**Automatische Snapshots von `/home`** (stündlich, Retention 6h/7d/4w/2m):

```bash
snapper -c home list                       # alle Snapshots
snapper -c home status 42..0                # was hat sich seit Snapshot 42 geändert
snapper -c home undochange 42..0            # zurückrollen
ls /home/.snapshots/42/snapshot/            # oder einfach Dateien rauskopieren
```

**Snapshot vor einem riskanten Rebuild:**

```bash
sudo snapper -c home create -d "vor hyprland-umbau"
```

**Compression prüfen** — auf einem Nix-Store lohnt zstd deutlich:

```bash
sudo compsize /nix
```

**Scrub** läuft wöchentlich automatisch (`services.btrfs.autoScrub`), manuell:

```bash
sudo btrfs scrub start /
sudo btrfs scrub status /
```

**Freien Platz richtig ablesen** — `df` lügt bei btrfs:

```bash
sudo btrfs filesystem usage /
```

### Optionale Erweiterungen

- **Snapshots von `/`**: `configs.root` in `systems/braavos/default.nix` ist
  auskommentiert vorbereitet, das Subvolume `/.snapshots` existiert schon.
  Bei NixOS meist unnötig, weil Boot-Generations dasselbe leisten.
- **`/var/log` als eigenes Subvolume**, damit Root-Snapshots keine Logs
  enthalten — müsste in `disko.nix` ergänzt und bei einem Neuinstall angelegt
  werden (nachträglich: `btrfs subvolume create` + Umkopieren).
- **`btrbk`/`btrfs send` für inkrementelle Offsite-Backups** — der eigentliche
  große Gewinn gegenüber ext4, aber ein eigenes Thema.
