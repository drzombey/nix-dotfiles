{ pkgs, flake, ... }: {

  home.packages = with pkgs; [
    flake.inputs.devenv.packages.${system}.devenv
    cachix
    nixpkgs-fmt
    sops
    age
    git
    jq
    htop
    wget
  ];
}

