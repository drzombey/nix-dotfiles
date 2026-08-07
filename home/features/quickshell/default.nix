{ pkgs, ... }:

let
  # Store-Pfad der QML-Konfiguration. Dient gleichzeitig als Restart-Trigger:
  # ändert sich der Inhalt, startet systemd die Shell nach dem Switch neu.
  shellConfig = ./config;
in
{
  home.packages = [ pkgs.quickshell ];

  # recursive statt eines Symlinks auf das ganze Verzeichnis: Quickshell leitet
  # QML-Modulnamen aus den Verzeichnisnamen unterhalb von ~/.config/quickshell
  # ab, und ein echtes Verzeichnis mit einzelnen Symlinks darin ist dafür der
  # unkompliziertere Fall.
  xdg.configFile."quickshell" = {
    source = shellConfig;
    recursive = true;
  };

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell — Bar und Shell-Oberfläche";
      Documentation = "https://quickshell.org";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      # Ohne graphische Session hat die Shell nichts zu tun.
      Requisite = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${shellConfig}" ];
    };

    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs";
      Restart = "on-failure";
      RestartSec = 2;
      Slice = "session.slice";
      # Qt findet die Zeitzonendatenbank auf NixOS sonst nicht
      # (/etc/localtime zeigt auf /etc/zoneinfo, nicht /usr/share/zoneinfo).
      Environment = [ "TZDIR=/etc/zoneinfo" ];
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
