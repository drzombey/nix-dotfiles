{ sops
, config
, pkgs
, ...
}: {
  sops = {
    age.keyFile = "${
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/tim/.config/sops/age/keys.txt"
    else "/home/tim/.config/sops/age/keys.txt"
    }";

    defaultSopsFile = ./secrets.yaml;
  };

}