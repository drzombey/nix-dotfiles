{ pkgs
, sops-nix
, ...
}: {

  imports = [
    sops-nix.homeManagerModule
    ./features/shell
    ./features/packages
    ./features/git
    ./features/nvim
    #./features/secrets
    ./features/tmux
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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
