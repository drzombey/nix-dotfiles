{ pkgs
, remapKeys
, ...
}: {
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.0;

    autohide-time-modifier = 0.2;
    expose-animation-duration = 0.2;
    tilesize = 48;
    launchanim = false;
    static-only = false;
    showhidden = true;
    show-recents = false;
    show-process-indicators = true;
    orientation = "bottom";
    mru-spaces = false;
  };

  system.keyboard = {
    enableKeyMapping = true;
    swapLeftCommandAndLeftAlt = remapKeys;

    # use https://hidutil-generator.netlify.app/ and convert hex to decimal
    userKeyMapping = [
      {
        HIDKeyboardModifierMappingSrc = 30064771300;
        HIDKeyboardModifierMappingDst = 30064771302;
      }
    ];
  };
}