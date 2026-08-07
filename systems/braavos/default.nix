{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./camera
  ];

  # Bootloader: Secure Boot via lanzaboote. Kernel + Initrd + Cmdline werden
  # zu einer UKI verschmolzen und mit dem eigenen db-Key signiert; lanzaboote
  # ersetzt dabei das systemd-boot-Modul, deshalb muss das hier aus (es
  # installiert sonst eine zweite, unsignierte Version daneben).
  boot.loader.systemd-boot.enable = false;
  # Wird von boot.lanzaboote.configurationLimit als Default geerbt.
  # Faustregel für die ESP: ~60 MB pro Generation (14 MB Kernel + 45 MB
  # Initrd), bei 1 GB /boot also nicht viel höher drehen.
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.lanzaboote = {
    enable = true;
    # sbctl-Default seit v0.14. Liegt außerhalb des Nix-Stores, weil der
    # private db-Key nichts im world-readable Store zu suchen hat — heißt
    # aber auch: nicht deklarativ, nach einem Neuinstall neu erzeugen.
    pkiBundle = "/var/lib/sbctl";
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.systemd.enable = true;

  # Btrfs: wöchentlicher Scrub verifiziert alle Checksummen und findet
  # schleichende Bitfehler. Scrub läuft pro Dateisystem, nicht pro Subvolume —
  # "/" deckt also home/nix/.snapshots mit ab (sonst 4x derselbe Scrub).
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  # Automatische Snapshots von /home mit Retention.
  # Zugriff: `snapper -c home list`, Rollback: `snapper -c home undochange <n>..0`
  # Read-only Snapshots liegen durchsuchbar unter /home/.snapshots/<n>/snapshot
  services.snapper = {
    snapshotInterval = "hourly";
    # Verpasste Timer nach Suspend/Shutdown nachholen (Laptop)
    persistentTimer = true;
    configs.home = {
      SUBVOLUME = "/home";
      ALLOW_USERS = [ "tim" ];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 6;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 2;
      TIMELINE_LIMIT_YEARLY = 0;
    };
    # Snapshots von / sind bei NixOS meist unnötig (Boot-Generations können
    # das schon). Bei Bedarf: Subvolume /.snapshots ist in disko.nix angelegt.
    # configs.root = {
    #   SUBVOLUME = "/";
    #   TIMELINE_CREATE = false;   # nur manuelle/pre-post Snapshots
    #   TIMELINE_CLEANUP = true;
    # };
  };

  networking.hostName = "braavos";
  networking.networkmanager.enable = true;

  # Automatische Garbage Collection + Store-Deduplizierung
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # Flakes + Cachix
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # tim darf Caches/Substituter selbst nutzen (cachix use <name>)
    trusted-users = [ "root" "tim" ];
    substituters = [ "https://devenv.cachix.org" ];
    trusted-public-keys = [ "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "de_DE.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };
  console.keyMap = "de";

  # Hyprland + Login-Manager
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;
  services.displayManager.defaultSession = "hyprland";
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    wayland.compositor = "kwin";
    settings.General.GreeterEnvironment = "KWIN_FORCE_SW_CURSOR=1";
  };
  # Electron-/Chrome-Apps nativ unter Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # dconf: Backend für GTK-/Theme-Einstellungen (Home-Manager schreibt dorthin)
  programs.dconf.enable = true;

  # GNOME Keyring (Secret Service, u.a. für 1Password/2FA)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # Audio (PipeWire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Grafik / Bluetooth / Firmware
  hardware.graphics.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  services.fwupd.enable = true;
  services.thermald.enable = true;
  # Liefert auch die Energieprofile für die Bar (net.hadess.PowerProfiles)
  services.power-profiles-daemon.enable = true;

  # sudo-Passwort 30 Min gültig (pro Terminal)
  security.sudo.extraConfig = "Defaults timestamp_timeout=30";

  # Docker
  virtualisation.docker.enable = true;

  # Fish als Login-Shell (Konfiguration via Home-Manager)
  programs.fish.enable = true;

  users.users."tim" = {
    isNormalUser = true;
    description = "Tim Lange";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
  };

  nixpkgs.config.allowUnfree = true;

  programs.direnv.enable = true;

  # 1Password (App + CLI); SSH-Agent wird in der App aktiviert
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "tim" ];
  };

  environment.systemPackages = with pkgs; [
    # Dev-Basics
    git
    vim
    curl
    wget
    htop
    cachix
    mise
    claude-code
    compsize # zeigt die echte btrfs-Compression-Ratio pro Pfad
    sbctl # Secure-Boot-Keys verwalten und Signaturen prüfen
    e2fsprogs # chattr/lsattr — nötig, um efivarfs-Variablen zum Enrollen zu entsperren

    # Apps
    google-chrome
    slack

    # Hyprland-Umgebung
    ghostty
    wofi
    mako
    hyprpolkitagent
    nautilus
    networkmanagerapplet
    brightnessctl
    playerctl
    pamixer
    grim
    slurp
    wl-clipboard
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    # Reine Icon-Schrift für die Quickshell-Bar: die Glyphen liegen in Unicode-
    # Private-Use-Bereichen, deshalb wird sie dort direkt adressiert.
    nerd-fonts.symbols-only
    inter
    noto-fonts
    noto-fonts-color-emoji
  ];

  services.openssh.enable = true;

  system.stateVersion = "26.05";
}
