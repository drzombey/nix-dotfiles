{ pkgs
, ...
}: {
  environment.variables = {
    HOMEBREW_AUTO_UPDATE_SECS = "604800";
  };
  
  homebrew = {
    enable = true;
    
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };

    taps = [
    ];

    brews = [
      "helm"
      "k6"
    ];

    casks = [
      "bruno"
      "brave-browser"
      "hammerspoon"
    ];
  };
}
