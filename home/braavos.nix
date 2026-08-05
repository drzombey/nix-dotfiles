{ config
, pkgs
, lib
, flake
, ... }:

{
  imports = [
    ./features/shell
    ./features/git
    ./features/nvim
    ./features/tmux
    ./features/hyprland
    ./features/ghostty
  ];

  home.stateVersion = "26.05";

  home.username = "tim";
  home.homeDirectory = "/home/tim";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
}
