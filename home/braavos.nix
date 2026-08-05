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
    ./features/theme
    ./features/claude
  ];

  home.stateVersion = "26.05";

  home.username = "tim";
  home.homeDirectory = "/home/tim";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Rebuild ohne Flake-Pfad: Hostname (braavos) wählt das Flake-Target automatisch
  home.shellAliases = {
    nrs = "sudo nixos-rebuild switch --flake /home/tim/nix-dotfiles";
    nrb = "nix build /home/tim/nix-dotfiles#nixosConfigurations.braavos.config.system.build.toplevel";
  };

  programs.home-manager.enable = true;
}
