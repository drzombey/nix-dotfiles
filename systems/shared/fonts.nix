{ pkgs
, remapKeys
, ...
}: {
  fonts = {
    packages = [
      ( pkgs.nerdfonts.override {
        fonts = [
          "Hack"
        ];
      } )
    ];
  };
}
