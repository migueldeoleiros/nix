{
  description = "NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
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

      nixExperimentalFeatures = {
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
      };

      nitroHost = {
        hostName = "nitro";
        mainMonitor = "HDMI-A-1";
        secondMonitor = "eDP-1";
        hasNvidia = true;
        tabletOutput = "HDMI-A-1";
        defaultScreenConfig = "custom_three.conf";
        batteryId = "BAT1";
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
        defaultScreenConfig = "screen_on_right.conf";
        batteryId = "BAT0";
        monitors = {
          a = { name = "eDP-1"; resX = 1920; resY = 1200; };
          b = { name = "DP-8"; resX = 2560; resY = 1440; };
          c = { name = "DP-1"; };
        };
      };

      frameworkHost = {
        hostName = "framework";
        mainMonitor = "eDP-1";
        secondMonitor = "DP-10";
        hasNvidia = false;
        tabletOutput = "eDP-1";
        defaultScreenConfig = "screen_on_right.conf";
        batteryId = "BAT1";
        monitors = {
          a = { name = "eDP-1"; resX = 2256; resY = 1504; };
          b = { name = "DP-10"; resX = 2560; resY = 1440; };
          c = { name = "DP-4"; };
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
            nixExperimentalFeatures
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

        framework = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit system inputs vars;
            host = frameworkHost;
          };
          modules = [
            nixExperimentalFeatures
            ./hosts/framework/default.nix
            { nixpkgs.pkgs = pkgs; }

            home-manager.nixosModules.home-manager {
              home-manager.extraSpecialArgs = {
                inherit vars inputs;
                host = frameworkHost;
              };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${vars.user} = import ./hosts/framework/home.nix;
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
          modules = [
            nixExperimentalFeatures
            ./hosts/yoga/home.nix
          ];
        };
      };
    };
}
