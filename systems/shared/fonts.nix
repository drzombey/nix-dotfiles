{ pkgs
, remapKeys
, ...
}: {
  fonts = {
    fontDir.enable = true;
    fonts = [
      ( pkgs.nerdfonts.override {
        fonts = [
          "Hack"
        ];
      } )
    ];
  };
}
