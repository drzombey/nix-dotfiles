{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.systemd.enable = true;

  boot.initrd.luks.devices."luks-c4a0a35b-8745-4d8c-a95e-cbc0af4e8310".device = "/dev/disk/by-uuid/c4a0a35b-8745-4d8c-a95e-cbc0af4e8310";

  networking.hostName = "braavos";
  networking.networkmanager.enable = true;

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  # Docker
  virtualisation.docker.enable = true;

  users.users."tim" = {
    isNormalUser = true;
    description = "Tim Lange";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
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

    # Apps
    google-chrome
    slack

    # Hyprland-Umgebung
    ghostty
    waybar
    wofi
    mako
    hyprlock
    hypridle
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
