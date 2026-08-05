{ pkgs, lib, ... }: {

  home.packages = with pkgs; [
    neovim

    # LazyVim-Grundbedarf
    ripgrep
    unzip
    gnumake
    gcc
    nodejs
    tree-sitter
    stylua
    lua-language-server
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    # Go-Tooling aus nixpkgs statt mason (mason-Binaries laufen auf NixOS nicht)
    go
    gopls
    delve
    gotools
    gofumpt
  ];

  # LazyVim-Config: privates Repo drzombey/lazyvim, muss schreibbar bleiben
  # (LazyVim pflegt lazy-lock.json selbst). Kein Auto-Clone hier, weil die
  # Home-Manager-Aktivierung als Systemdienst ohne SSH-Agent läuft:
  #   git clone git@github.com:drzombey/lazyvim.git ~/.config/nvim
}
