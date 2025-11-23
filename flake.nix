{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }:
    let
      vars = {
        user = "miguel";
      };
    in {
      nixosConfigurations = (
        import ./nixos {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs home-manager vars;
        }
      );
    };
}
