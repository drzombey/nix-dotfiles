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
      "platformsh/tap"
      "vitobotta/tap"
    ];

    brews = [
      "platformsh-cli"
      "argocd"
      "dnsmasq"
      "hetzner_k3s"
      "helm"
    ];

    casks = [
      "bruno"
      "brave-browser"
      "openlens"
    ];
  };
}
