{ config
, pkgs
, lib
, flake
, ... }:

{
   imports = [
    flake.inputs.mac-app-util.homeManagerModules.default
    ./features/shell
    ./features/packages
    ./features/nvim
    ./features/tmux
    ./features/secrets
    ./features/git
    ./features/1password
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  nixpkgs.config.allowUnfreePredicate = _: true;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.username = "tim";
  home.homeDirectory = "${
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/tim"
    else "/home/tim"
  }";

  programs.home-manager.enable = true;

}