{ pkgs
, remapKeys
, ...
}: {
  fonts = {
    packages = [
      pkgs.nerd-fonts.hack
    ];
  };
}
