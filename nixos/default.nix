{ lib, inputs, nixpkgs, home-manager, vars, ... }:

let
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  lib = nixpkgs.lib;
in
{
  miguel = lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit system pkgs inputs vars;
      host = {
        hostName = "nitro";
        mainMonitor = "HDMI-1";
        secondMonitor = "eDP-1";
      };
    };
    modules = [
      ./configuration.nix
      ./hardware-configuration.nix

      home-manager.nixosModules.home-manager {
        home-manager.extraSpecialArgs = { inherit vars inputs; };
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
    ];
  };
}
