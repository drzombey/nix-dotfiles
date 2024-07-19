{ pkgs
, ...
}: {

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
      "colima"
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

  system.activationScripts.postUserActivation.text = ''
      $DRY_RUN_CMD rm -rf $VERBOSE_ARG ~/.colima/default
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.colima/default
      $DRY_RUN_CMD cp $VERBOSE_ARG ${configs/colima/colima.yaml} ~/.colima/default/colima.yaml
      $DRY_RUN_CMD chmod 644 $VERBOSE_ARG ~/.colima/default/colima.yaml
    '';
}
