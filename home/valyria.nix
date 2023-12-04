{ config
, pkgs
, lib
, ... }:

{
  imports = [
    ./default.nix
  ];

  home.username = "tim";
  home.homeDirectory = lib.mkForce "/Users/tim";

  home.packages = with pkgs; [
    skhd
    alacritty
  ];
}
