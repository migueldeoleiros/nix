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

      nitroHost = {
        hostName = "nitro";
        mainMonitor = "HDMI-A-1";
        secondMonitor = "eDP-1";
        hasNvidia = true;
        tabletOutput = "HDMI-A-1";
        monitors = {
          a = { name = "eDP-1"; resX = 1920; resY = 1080; };
          b = { name = "HDMI-A-1"; resX = 2560; resY = 1440; };
          c = { name = "DVI-I-1"; };
        };
      };

      yogaHost = {
        hostName = "yoga";
        mainMonitor = "eDP-1";
        secondMonitor = "DP-2";
        hasNvidia = false;
        tabletOutput = "DP-8";
        monitors = {
          a = { name = "eDP-1"; resX = 1920; resY = 1200; };
          b = { name = "DP-8"; resX = 2560; resY = 1440; };
          c = { name = "DP-1"; };
        };
      };

    in {
      # NixOS configurations
      nixosConfigurations = {
        miguel = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit system inputs vars;
            host = nitroHost;
          };
          modules = [
            ./hosts/nitro/default.nix
            { nixpkgs.pkgs = pkgs; }

            home-manager.nixosModules.home-manager {
              home-manager.extraSpecialArgs = {
                inherit vars inputs;
                host = nitroHost;
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
            host = yogaHost;
          };
          modules = [ ./hosts/yoga/home.nix ];
        };
      };
    };
}
