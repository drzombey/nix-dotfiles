{ config
, pkgs
, lib
, flake
, ... }:

{
  imports = [
    ./default.nix
  ];

  home.packages = with pkgs; [
    alacritty
    _1password-cli
    coreutils
    go_1_23
    pigz
    ssm-session-manager-plugin
    wireguard-tools
    kubectl
    kubectx
    docker-client
    dive
    bun
    k9s
    kubectx
    kubectl-neat
    gh
    k6
    awscli2
    spotify
    gnused
    act
    cilium-cli
    colmena
  ];
}
