{ config, lib, pkgs, ... }:

# Intel IPU7 MIPI-Kamera (Panther Lake / XPS 16, Sensor ov08x40).
#
# Warum das so aufwendig ist: eine MIPI-Kamera ist keine Webcam. Der Sensor
# liefert nur rohe 12-bit-Bayer-Daten, die die IPU (Image Processing Unit) der
# CPU erst zu einem Bild entwickeln muss. Der Stack besteht deshalb aus vier
# Teilen, von denen der Kernel nur den ersten mitbringt:
#
#   1. ISYS  — nimmt die Rohframes vom Sensor entgegen  (Kernel, staging)
#   2. PSYS  — die eigentliche Hardware-ISP             (out-of-tree, s.u.)
#   3. HAL   — steuert PSYS + 3A (AE/AWB/AF) im Userspace, proprietär
#   4. Relay — schiebt das Ergebnis in ein v4l2loopback-Gerät, damit
#              Browser/Slack/OBS eine ganz normale /dev/video50 sehen
#
# Portiert aus dem Omarchy-Paket intel-ipu7-camera:
# https://github.com/omacom-io/omarchy-pkgs/tree/master/pkgbuilds/intel-ipu7-camera
# Sobald https://github.com/NixOS/nixpkgs/pull/479283 gemergt ist, sollte das
# hier durch `hardware.ipu7.enable = true` ersetzbar sein.

let
  # Feste Loopback-Nummer: PipeWire leitet den Node-Namen aus dem sysfs-Pfad
  # ab, und Chrome/Slack hängen ihre Kamera-Berechtigung an diesen Namen.
  # Wandert das Gerät bei jedem Boot, sind die Freigaben weg.
  videoNr = 50;

  ipuVersion = "ipu75xa"; # Panther Lake

  ipu7-camera-bins = pkgs.callPackage ./pkgs/ipu7-camera-bins.nix { };
  ipu7-camera-hal = pkgs.callPackage ./pkgs/ipu7-camera-hal.nix {
    inherit ipu7-camera-bins ipuVersion;
  };
  icamerasrc = pkgs.callPackage ./pkgs/icamerasrc.nix {
    inherit ipu7-camera-hal;
  };

  ipu7-drivers = config.boot.kernelPackages.callPackage ./pkgs/ipu7-drivers.nix { };
  vision-drivers = config.boot.kernelPackages.callPackage ./pkgs/vision-drivers.nix { };
in
{
  boot.extraModulePackages = [
    ipu7-drivers
    vision-drivers
  ];

  # Der Sensor darf erst hoch, wenn intel_cvs die Kamera übernommen hat —
  # sonst läuft sein I2C-Probe in einen Timeout. ipu-bridge würde ov08x40
  # aber sofort per Alias nachziehen, deshalb Auto-Load abschalten und das
  # Laden unten explizit sequenzieren.
  boot.blacklistedKernelModules = [ "ov08x40" ];
  boot.extraModprobeConfig = ''
    softdep ov08x40 pre: intel_cvs
  '';

  hardware.firmware = [
    ipu7-camera-bins
    pkgs.ivsc-firmware
  ];

  systemd.services.ipu7-camera-init = {
    description = "Intel IPU7 camera bring-up (CVS ownership, sensor)";
    wantedBy = [ "multi-user.target" ];
    before = [ "v4l2-relayd-ipu7.service" ];
    requiredBy = [ "v4l2-relayd-ipu7.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [ pkgs.kmod ];
    script = ''
      modprobe intel_cvs
      # Die CVS-Firmware braucht einen Moment, bis sie den Sensor übernommen
      # und die USBIO-GPIO für dessen Stromversorgung geschaltet hat.
      sleep 2
      modprobe ov08x40
    '';
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="intel-ipu7-psys", MODE="0660", GROUP="video"

    # Die 32 ISYS-Capture-Nodes liefern rohes Bayer und sind für Anwendungen
    # nutzlos — würden in Kamera-Auswahldialogen aber als 32 tote Geräte
    # auftauchen. MODE 0600 + GROUP root sperrt sie auch für die video-Gruppe;
    # TAG-="uaccess" verhindert, dass logind beim Login doch noch eine ACL setzt.
    SUBSYSTEM=="video4linux", ATTR{name}=="Intel IPU7 ISYS Capture *", TAG-="uaccess", TAG-="seat", MODE="0600", GROUP="root"
    SUBSYSTEM=="media", DRIVERS=="intel-ipu7", MODE="0600", GROUP="root", TAG-="uaccess"
  '';

  # libcamhal legt hier AIQ-Tuning-Daten und Logs ab.
  systemd.tmpfiles.rules = [ "d /run/camera 0755 root video -" ];

  # Gleiches Spiel für PipeWire: die rohen IPU7-Nodes ausblenden, damit
  # ausschließlich das Loopback-Gerät als Kamera angeboten wird.
  services.pipewire.wireplumber.extraConfig."50-ipu7-hide-raw" = {
    "monitor.v4l2.rules" = [
      {
        matches = [ { "device.bus-path" = "pci-0000:00:05.0"; } ];
        actions."update-props"."device.disabled" = true;
      }
    ];
  };

  services.v4l2-relayd.instances.ipu7 = {
    enable = true;
    cardLabel = "Intel MIPI Camera";
    extraPackages = [ icamerasrc ];

    input = {
      # device-name muss zu einer sensors/*.json der HAL passen:
      # ipu7-camera-hal/config/linux/ipu75xa/sensors/ov08x40-uf.json
      #
      # Der Sensor ist im Deckel um 180° verdreht verbaut. Über den ACPI-Pfad
      # kommt keine Orientierungsinfo mit (die läge in _PLD/SSDB, die aber nur
      # ipu_bridge auswertet — und die umgehen wir ja gerade), also wird hier
      # in der Pipeline gedreht.
      #
      # Bewusst nur gedreht und nicht gespiegelt: was hier in die Pipeline
      # kommt, geht auch so an die Gegenseite raus. Das Selbstbild spiegeln
      # Videocall-Anwendungen selbst — täte man es hier, sähen die anderen
      # einen spiegelverkehrten Stream (vertical-flip wäre die Variante mit
      # Spiegelung).
      pipeline = "icamerasrc device-name=ov08x40-uf ! videoflip method=rotate-180";
      format = "NV12";
      width = 1920;
      height = 1080;
      framerate = 30;
    };
  };

  # preStart/postStop des v4l2-relayd-Moduls ersetzen:
  #  - feste Gerätenummer statt der nächsten freien (s. videoNr oben);
  #    Exit 17 (EEXIST) heißt "gibt's schon" und ist Erfolg.
  #  - das Loopback beim Stoppen stehen lassen, damit laufende Anwendungen
  #    über einen Relay-Neustart hinweg nur blockieren statt Fehler zu sehen.
  systemd.services.v4l2-relayd-ipu7 = {
    preStart = lib.mkForce ''
      mkdir -p "$(dirname "$V4L2_DEVICE_FILE")"
      ${config.boot.kernelPackages.v4l2loopback.bin}/bin/v4l2loopback-ctl \
        add --name "Intel MIPI Camera" --exclusive-caps=1 ${toString videoNr} || [ $? -eq 17 ]
      echo /dev/video${toString videoNr} > "$V4L2_DEVICE_FILE"
    '';
    postStop = lib.mkForce ''
      rm -rf "$(dirname "$V4L2_DEVICE_FILE")"
    '';
  };

  # v4l-utils für die Fehlersuche (media-ctl, v4l2-ctl), gst-launch-1.0 um die
  # Pipeline ohne Relay direkt testen zu können.
  environment.systemPackages = [
    pkgs.v4l-utils
    pkgs.gst_all_1.gstreamer.dev
    icamerasrc
  ];
}
