# Deklaratives Plattenlayout für braavos (disko).
#
# GPT: ESP (1G) + LUKS-Swap (68G) + LUKS-Btrfs (Rest)
# Beide LUKS-Container bekommen die *gleiche* Passphrase — systemd-initrd
# cached die erste Eingabe im Kernel-Keyring und probiert sie beim zweiten
# Container automatisch, es gibt also nur einen Prompt beim Booten.
#
# Achtung: `disko --mode destroy,format,mount` LÖSCHT die Platte.
# Ablauf für den Neuinstall: docs/braavos-btrfs.md
{
  disko.devices.disk.main = {
    type = "disk";
    # Stabiler Pfad (EUI64 der NVMe) — bleibt auch beim Boot von der Install-ISO gleich
    device = "/dev/disk/by-id/nvme-eui.fd5b42cebc8f9d54ace42e00616be94b";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0077" "dmask=0077" ];
          };
        };

        # Eigene Swap-Partition statt Swapfile auf btrfs: damit funktioniert
        # Hibernation ohne resume_offset-Gefummel. 68G > 62G RAM.
        swap = {
          priority = 2;
          size = "68G";
          content = {
            type = "luks";
            name = "cryptswap";
            settings.allowDiscards = true;
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
        };

        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            # TRIM durch dm-crypt durchlassen (SSD-Lebensdauer/Performance).
            # Tradeoff: verrät belegte vs. freie Blöcke an einen Angreifer.
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [ "-f" "--label" "braavos" ];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                # snapper braucht ein Subvolume .snapshots *innerhalb* des
                # überwachten Subvolumes — das NixOS-Modul legt es nicht an.
                "/home/.snapshots" = {
                  mountpoint = "/home/.snapshots";
                  mountOptions = [ "noatime" ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                # Auf Vorrat, damit ein snapper-Config für / später ohne
                # Anfassen der Platte aktivierbar ist (siehe default.nix).
                "/snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [ "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
