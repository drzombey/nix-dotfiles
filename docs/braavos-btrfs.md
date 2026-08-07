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

## 5b. Secure Boot einrichten (lanzaboote)

Reihenfolge beachten: **erst Secure Boot, dann TPM.** Das Einschalten von
Secure Boot verändert PCR 7, und genau daran hängt der TPM-Keyslot — andersrum
darf man alles zweimal machen.

lanzaboote ist in `flake.nix` und `systems/braavos/default.nix` schon
konfiguriert. Was nicht deklarativ geht: die Keys selbst. Der private db-Key
liegt in `/var/lib/sbctl` und hat im world-readable Nix-Store nichts verloren,
also nach jedem Neuinstall einmal von Hand:

Henne/Ei: `sbctl` steht in `systemPackages`, ist also erst *nach* dem Rebuild
im PATH — die Keys müssen aber *vorher* existieren, sonst hat lanzaboote nichts
zum Signieren und der Rebuild bricht bei der Bootloader-Installation ab. Also
für den ersten Aufruf direkt aus dem Store:

```bash
sudo $(nix build --no-link --print-out-paths \
  /home/tim/nix-dotfiles#nixosConfigurations.braavos.pkgs.sbctl)/bin/sbctl create-keys

sudo nixos-rebuild switch --flake /home/tim/nix-dotfiles#braavos
sudo sbctl verify                                             # ab jetzt im PATH
```

`sbctl verify` muss für `BOOTX64.EFI`, `systemd-bootx64.efi` und die
`EFI/Linux/nixos-generation-*.efi` ein ✓ zeigen. Die rohen `*-bzImage.efi`
unter `EFI/nixos/` sind erwartungsgemäß **nicht** signiert — die werden bei
lanzaboote nicht direkt gebootet, der Kernel steckt in der UKI.

### Firmware in den Setup Mode (Dell XPS 16)

Beim Booten F2 für das BIOS, dann:

1. **Security → Secure Boot**: „Enable Secure Boot" auf **On**
2. **Secure Boot Mode** von „Deployed Mode" auf **„Audit Mode"** stellen —
   das löscht den Platform Key und ist bei Dell der Weg in den Setup Mode
3. F10, speichern und neu starten

> **Nicht** „Delete all Secure Boot Settings" / „Clear All Keys" nehmen. Das
> wirft auch die dbx (Forbidden Signature Database, aktuell ~19 kB) weg, und
> die bekommt man nur über „Restore Factory Keys" + Neuanfang zurück.

Nach dem Reboot prüfen, dass die Firmware wirklich im Setup Mode ist:

```bash
sudo sbctl status        # Setup Mode: ✓ Enabled
```

### Keys enrollen

Der Kernel setzt auf schon existierende EFI-Variablen ein Immutable-Flag.
KEK und db müssen deshalb vorher entsperrt werden, sonst bricht `enroll-keys`
mit „File is immutable / You need to chattr -i files in efivarfs" ab. Die GUIDs
stehen in der Fehlermeldung; **die `dbx-*` nicht anfassen**:

```bash
sudo chattr -i /sys/firmware/efi/efivars/KEK-8be4df61-93ca-11d2-aa0d-00e098032b8c \
               /sys/firmware/efi/efivars/db-d719b2cb-3d3a-4596-a3bc-dad00e67656f

sudo sbctl enroll-keys --microsoft
```

`--microsoft` ist hier nicht optional: das Dell-Gerät hat Option ROMs
(Thunderbolt, dGPU), die mit Microsoft-Keys signiert sind. Ohne die
MS-Zertifikate startet die Kiste im schlimmsten Fall nicht mehr durch.

Dann rebooten, im BIOS **Secure Boot Mode zurück auf „Deployed Mode"**, und
verifizieren:

```bash
bootctl status | grep 'Secure Boot'    # → enabled (user)
sudo sbctl status                       # Setup Mode: ✗ Disabled, Secure Boot: ✓ Enabled
```

### Wenn es nicht bootet

Die alten Generations in der ESP sind mitsigniert, das Fallback ist also
schlicht: BIOS → Secure Boot auf Off, booten, Problem in Ruhe angucken.
Deshalb auch nichts löschen, bevor der erste signierte Boot geklappt hat.
Zurückbauen komplett: `boot.lanzaboote.enable = false` +
`boot.loader.systemd-boot.enable = true`, rebuilden, `sudo sbctl reset`.

Kernel-Lockdown ist im NixOS-Kernel nicht aktiv
(`CONFIG_SECURITY_LOCKDOWN_LSM is not set`), Hibernation und ungetestete
Kernelmodule funktionieren also mit Secure Boot weiter wie vorher.

BIOS-Updates über fwupd laufen auch weiter: sobald `boot.lanzaboote.enable`
gesetzt ist, zieht das NixOS-fwupd-Modul eine `fwupd-efi.service` hoch, die
`fwupdx64.efi` vor jedem `fwupd.service` mit dem db-Key aus `/var/lib/sbctl`
signiert. Nichts zu tun, aber gut zu wissen, warum es funktioniert.

## 5c. TPM2-Entsperrung einrichten

`tpm2-device=auto` steht schon in `disko.nix`, aber der TPM-Keyslot lebt im
LUKS-Header auf der Platte und wird beim Neuinstall mitgelöscht — also nach
jedem Format einmal von Hand nachziehen. Erst rebuilden, damit die
crypttab-Option im Initrd landet:

```bash
sudo nixos-rebuild switch --flake /home/tim/nix-dotfiles#braavos

# --wipe-slot=tpm2 macht das Ganze idempotent (alter Slot raus, neuer rein).
# Fragt je einmal nach der bestehenden LUKS-Passphrase.
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto /dev/nvme0n1p2   # cryptswap
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto /dev/nvme0n1p3   # cryptroot
```

Prüfen (`systemd-tpm2` als Token, Passphrase weiterhin in Slot 0):

```bash
sudo cryptsetup luksDump /dev/nvme0n1p3 | grep -E 'Keyslot|systemd-tpm2'
```

Ohne `--tpm2-pcrs` bindet systemd-cryptenroll an **PCR 7** — den
Secure-Boot-Zustand inklusive des Zertifikats, mit dem das gebootete Image
verifiziert wurde. Mit aktivem Secure Boot und eigenen Keys heißt das: nur eine
mit dem eigenen db-Key signierte UKI bekommt den Schlüssel. Ein Live-USB kommt
gar nicht erst so weit.

Neu enrollen also immer dann, wenn sich der Secure-Boot-Zustand ändert:
Ein/Aus-Schalten, `sbctl enroll-keys` erneut laufen lassen, Keys tauschen. PCR 7
ist unabhängig von Kernel- und Generation-Updates, normale Rebuilds ändern
daran nichts. Wenn der TPM den Key mal nicht rausrückt, fragt das Initrd
einfach nach der Passphrase — nichts geht verloren. Entfernen:
`sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p3`.

## 6. Verifizieren

```bash
findmnt -t btrfs                  # Subvolumes gemountet?
sudo btrfs subvolume list /       # root, home, home/.snapshots, nix, snapshots
sudo compsize /home /nix          # Compression greift?
swapon --show                     # 68G aktiv
systemctl list-timers | grep -E 'snapper|btrfs'
sudo snapper -c home list         # nach der ersten Stunde nicht mehr leer

bootctl status | grep 'Secure Boot'   # enabled (user)
sudo sbctl verify                     # UKIs signiert
df -h /boot                           # ESP nicht vollgelaufen (~60 MB/Generation)
```

Und der eigentliche Test: rebooten und **keine** Passphrase eingeben müssen.

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
