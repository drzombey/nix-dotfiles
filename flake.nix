{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv.url = "github:cachix/devenv/v1.8.1";
    mac-app-util.url = "github:hraban/mac-app-util";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    { self
    , nixpkgs
    , nix-darwin
    , home-manager
    , devenv
    , sops-nix
    , ...
    }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      extraArgs = {
        inherit sops-nix;
        flake = self;
      };
    in
    {
      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };
          specialArgs = extraArgs;
        };
        "astapor" = {
          deployment.targetHost = "astapor.tail86ba67.ts.net";
          deployment.buildOnTarget = true;
          imports = [
            ./systems/astapor
            sops-nix.nixosModules.sops
          ];
        };
      };

      defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;
      defaultPackage.aarch64-darwin = home-manager.defaultPackage.aarch64-darwin;

      darwinConfigurations = {
        Valyria = nix-darwin.lib.darwinSystem {
          specialArgs = extraArgs // {
            remapKeys = false;
          };
          system = "aarch64-darwin";
          modules = [
            ./systems/valyria
            home-manager.darwinModules.default
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = extraArgs;
            }
          ];
        };
      };
    };
}
