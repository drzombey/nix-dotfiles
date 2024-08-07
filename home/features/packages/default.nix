{ pkgs, flake, ... }: {

  home.packages = with pkgs; [
    flake.inputs.devenv.packages.${system}.devenv
    cachix

    nixpkgs-fmt

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
    kubectx
    docker-client
    dive
    bun
    k9s
    kubectx
    gh
    k6
    awscli2
    spotify
    gnused
    act
  ];
}

