{
  description = "NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      vars = {
        user = "miguel";
      };

    in {
      # NixOS configurations
      nixosConfigurations = {
        miguel = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit system inputs vars;
            host = {
              hostName = "nitro";
              mainMonitor = "HDMI-1";
              secondMonitor = "eDP-1";
            };
          };
          modules = [
            ./hosts/nitro/default.nix
            { nixpkgs.pkgs = pkgs; }

            home-manager.nixosModules.home-manager {
              home-manager.extraSpecialArgs = {
                inherit vars inputs;
                host = {
                  hostName = "nitro";
                  mainMonitor = "HDMI-1";
                  secondMonitor = "eDP-1";
                };
              };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${vars.user} = import ./hosts/nitro/home.nix;
            }
          ];
        };
      };

      # Standalone home-manager configurations
      homeConfigurations = {
        "miguel@yoga" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit vars inputs;
            host = {
              hostName = "yoga";
              mainMonitor = "eDP-1";
              secondMonitor = "DP-2";
            };
          };
          modules = [ ./hosts/yoga/home.nix ];
        };
      };
    };
}
