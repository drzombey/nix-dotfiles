{ pkgs
, home-manager
, lib
, config
, ...
}: {
  imports = [
    ../shared/yabai.nix
    ../shared/skhd.nix
    ../shared/brew.nix
    ../shared/system.nix
    ../shared/fonts.nix
    ../shared/aerospace.nix
  ];

  users.users.tim = {
    home = "/Users/tim";
    shell = "${pkgs.fish}/bin/fish";
  };

  home-manager.users.tim = { 
    imports = [
      ../../home/valyria.nix
    ];
  };

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 2d";
    interval = {
      Hour = 5;
      Minute = 0;
    };
  };

  environment.systemPackages = with pkgs; [
    raycast
  ];

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;
  environment.shells = [ "${pkgs.fish}/bin/fish" ];

  documentation.enable = false;
  documentation.man.enable = false;

  time.timeZone = "Europe/Berlin";
  system.stateVersion = 5;
  ids.gids.nixbld = 30000;
  nix = {
    settings.trusted-users = [ "root" "tim" ];
  };
}
