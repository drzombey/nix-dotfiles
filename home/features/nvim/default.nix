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

  # LazyVim-Config: privates Repo drzombey/lazyvim, bleibt schreibbar
  # (LazyVim pflegt lazy-lock.json selbst) -> nur klonen, wenn nicht vorhanden.
  # Nutzt den 1Password-SSH-Agenten; der ist nur erreichbar, wenn die App läuft
  # und entsperrt ist. Fehlschlag darf den Switch nicht abbrechen -> "|| true".
  home.activation.cloneLazyVim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/nvim" ]; then
      if SSH_AUTH_SOCK="$HOME/.1password/agent.sock" \
         GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o BatchMode=yes" \
         ${pkgs.git}/bin/git clone git@github.com:drzombey/lazyvim.git \
           "$HOME/.config/nvim"; then
        echo "LazyVim-Config geklont."
      else
        echo "LazyVim-Config NICHT geklont (1Password entsperrt? Dann erneut 'nrs')." >&2
        rm -rf "$HOME/.config/nvim"
      fi
    fi
  '';
}
