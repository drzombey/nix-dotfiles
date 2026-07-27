{ pkgs, lib, ... }: {
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      netbird
      netbird-ui
    ];
}
