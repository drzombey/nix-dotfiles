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
      "aws/tap"
    ];

    brews = [
      "helm"
      "k6"
      "eks-node-viewer"
      "mysql-client"
      "istioctl"
    ];

    casks = [
      "bruno"
      "brave-browser"
      "hammerspoon"
    ];
  };
}
