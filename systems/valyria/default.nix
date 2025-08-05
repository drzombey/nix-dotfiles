{ pkgs
, home-manager
, lib
, config
, ...
}: {
  imports = [
    ../shared/determinate.nix
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

  environment.systemPackages = with pkgs; [
    raycast
  ];

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;
  environment.shells = [ "${pkgs.fish}/bin/fish" ];

  documentation.enable = false;
  documentation.man.enable = false;
  system.primaryUser = "tim";

  time.timeZone = "Europe/Berlin";
  system.stateVersion = 5;
  ids.gids.nixbld = 30000;
  nix = {
    settings.trusted-users = [ "root" "tim" ];
  };

  nix.enable = false;
}
