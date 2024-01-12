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
    ];

    brews = [
      "platformsh-cli"
    ];

    casks = [
      "bruno"
      "brave-browser"
    ];
  };
}
