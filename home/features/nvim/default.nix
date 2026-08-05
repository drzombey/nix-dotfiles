{ pkgs, lib, config, ... }: {

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

  # LazyVim-Config lebt in einem eigenen Repo und muss schreibbar bleiben
  # (LazyVim pflegt lazy-lock.json selbst) -> nur klonen, wenn nicht vorhanden.
  home.activation.cloneLazyVim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "${config.xdg.configHome}/nvim" ]; then
      run env GIT_CONFIG_GLOBAL=/dev/null ${pkgs.git}/bin/git clone \
        https://github.com/drzombey/lazyvim.git "${config.xdg.configHome}/nvim"
      run env GIT_CONFIG_GLOBAL=/dev/null ${pkgs.git}/bin/git -C "${config.xdg.configHome}/nvim" \
        remote set-url origin git@github.com:drzombey/lazyvim.git
    fi
  '';
}
