{ lib, pkgs, flake, ... }: {

  home.packages = with pkgs; [
    colima
  ];

  home.activation = {
    copyColimaConfig = lib.hm.dag.entryAfter ["InstallPackages"] ''
      $DRY_RUN_CMD rm -rf $VERBOSE_ARG ~/.colima/default
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.colima/default
      $DRY_RUN_CMD cp $VERBOSE_ARG ${configs/colima/colima.yaml} ~/.colima/default/colima.yaml
      $DRY_RUN_CMD chmod 644 $VERBOSE_ARG ~/.colima/default/colima.yaml
    '';
  };
}