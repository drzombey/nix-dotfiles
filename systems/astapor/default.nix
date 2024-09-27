{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./services.nix
  ];

  system.stateVersion = "24.11";
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "astapor";
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de-latin1";
  };

  users.users.tim = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    openssh.authorizedKeys.keys = [
     "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDCYPCL4vzkj8saRLC3MRgUrZGpKU3I2Po6XK0V6NsBS4RIb0HauOlinZEdCEdbFqGsCEpOZqIsjyiZmcecyTyK4Y6xeDFAyyatW6GV2wyQFdWJw/q6jWU+QCgWtG3SgfE4gKIKWZNbFB1L+g5PLkclLHy1s8AqauJUcxBnu1wdW/SlBl/HLuzKlEcXmRswv2esV1WVh3WJyNJCKhGL4qnfDS+BwRMCNfqsYzoY8xQdNT+SgmoM+rHiotEW8Tyy0MNLSrzk+QPZuHgNBWJHnc4j2Fv0s52CLRK34UFogDFrYutBEiCNpj4E8ABsSr/Ji4M5Jp+Hx11+kE7e/JctNSN28J4DGkVyDRjxINb5jmIbTEzYDcJKge3xPAH8lMEqCIYuFw4MSvwk8ptnbOPf113YVUMYSxeB1PcaLDp+vD6pjCcA3WwB19djdZH2iVOULWZYzkIl60qu0n322ZcAv2Ek0v+aMjpovRrC9Y/DsM2S08I7YtSN5Fs8CcNkimJQ/rs="
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
   "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDCYPCL4vzkj8saRLC3MRgUrZGpKU3I2Po6XK0V6NsBS4RIb0HauOlinZEdCEdbFqGsCEpOZqIsjyiZmcecyTyK4Y6xeDFAyyatW6GV2wyQFdWJw/q6jWU+QCgWtG3SgfE4gKIKWZNbFB1L+g5PLkclLHy1s8AqauJUcxBnu1wdW/SlBl/HLuzKlEcXmRswv2esV1WVh3WJyNJCKhGL4qnfDS+BwRMCNfqsYzoY8xQdNT+SgmoM+rHiotEW8Tyy0MNLSrzk+QPZuHgNBWJHnc4j2Fv0s52CLRK34UFogDFrYutBEiCNpj4E8ABsSr/Ji4M5Jp+Hx11+kE7e/JctNSN28J4DGkVyDRjxINb5jmIbTEzYDcJKge3xPAH8lMEqCIYuFw4MSvwk8ptnbOPf113YVUMYSxeB1PcaLDp+vD6pjCcA3WwB19djdZH2iVOULWZYzkIl60qu0n322ZcAv2Ek0v+aMjpovRrC9Y/DsM2S08I7YtSN5Fs8CcNkimJQ/rs="
  ];

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    bat
    ncdu
  ];
}
