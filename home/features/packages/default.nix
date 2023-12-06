{ pkgs, flake, ... }: {

  home.packages = with pkgs; [
    flake.inputs.devenv.packages.${system}.devenv
    cachix

    nixpkgs-fmt
    sops

    _1password
    jq
    htop
    coreutils
    pigz
    ssm-session-manager-plugin
    wget
    wireguard-tools
    mysql80
    kubectl
    colima
    docker-client
    dive
    bun
    k9s
    gh
    k6
    awscli2
  ];
}

