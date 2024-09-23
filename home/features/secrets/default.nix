{ sops
, config
, pkgs
, flake
, ...
}: {

  imports = [
    flake.inputs.sops-nix.homeManagerModule
  ];

  sops = {
    age.keyFile = "${
    if pkgs.stdenv.hostPlatform.isDarwin
    then "${config.users.users.username.home}/.config/sops/age/keys.txt"
    else "${config.users.users.username.home}/.config/sops/age/keys.txt"
    }";

    defaultSopsFile = ./secrets.yaml;
  };

}