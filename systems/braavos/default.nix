{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.systemd.enable = true;

  boot.initrd.luks.devices."luks-c4a0a35b-8745-4d8c-a95e-cbc0af4e8310".device = "/dev/disk/by-uuid/c4a0a35b-8745-4d8c-a95e-cbc0af4e8310";

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

    # Apps
    google-chrome
    slack

    # Hyprland-Umgebung
    ghostty
    waybar
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
    noto-fonts
    noto-fonts-color-emoji
  ];

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  system.stateVersion = "26.05";
}
