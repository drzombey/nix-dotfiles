{ config
, pkgs
, lib
, ... }:

{
  imports = [
    ./defaults/default.nix
  ];

  home.packages = with pkgs; [];

  targets.genericLinux.enable = true;
}
