{
  description = "NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    opencode-v2 = {
      url = "github:anomalyco/opencode/4617210822bdbb31e5749751afbfb4584ccedac8";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.vicinae.follows = "vicinae";
    };

  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.opencode-v2.overlays.default
          (final: prev: {
            # Upstream fix: https://github.com/NixOS/nixpkgs/pull/576488
            # The patched vendored Node crashes before CodeGraph starts.
            # Remove once the nixpkgs pin includes that fix.
            codegraph = prev.codegraph.overrideAttrs (old: {
              postInstall = (old.postInstall or "") + ''
                rm "$out/lib/codegraph/node"
                ln -s ${final.lib.getExe final.nodejs-slim} "$out/lib/codegraph/node"
              '';
            });
            stablyai-orca = final.callPackage ./pkgs/orca-ide.nix { };
          })
        ];
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
        keyboard = {
          layout = "us,es";
          variant = ",";
          options = "ctrl:nocaps,compose:ralt";
        };
        monitors = {
          a = { name = "eDP-1"; resX = 1920; resY = 1080; scale = "1"; };
          b = { name = "HDMI-A-1"; resX = 2560; resY = 1440; };
          c = { name = "DVI-I-1"; resX = 1080; resY = 1920; };
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
        keyboard = {
          layout = "us,es";
          variant = ",";
          options = "ctrl:nocaps,compose:ralt";
        };
        monitors = {
          a = { name = "eDP-1"; resX = 1920; resY = 1200; scale = "1"; };
          b = { name = "DP-8"; resX = 2560; resY = 1440; };
          c = { name = "DP-1"; resX = 1920; resY = 1080; };
        };
      };

      vmShellHost = {
        hostName = "vm-shell";
      };

      frameworkHost = {
        hostName = "DSK-046";
        hasNvidia = false;
        tabletOutput = "eDP-1";
        defaultScreenConfig = "custom_three_right.conf";
        batteryId = "BAT1";
        keyboard = {
          layout = "us";
          variant = "altgr-intl";
          options = "ctrl:nocaps";
        };
        monitors = {
          # Candidates are tried in order; a connected display fills at most one slot.
          # Add other desk/dock displays to these lists, identified by EDID, not port.
          a = {
            candidates = [ "desc:BOE 0x0BCA" ];
            resX = 2256; resY = 1504; scale = "1.175";
          };
          b = {
            candidates = [
              "desc:Philips Consumer Electronics Company PHL 245E1 0x00007D81"
              "desc:Samsung Electric Company S24F350 H4ZR201339"
            ];
            resX = 2560; resY = 1440;
          };
          c = {
            candidates = [ "desc:HP Inc. HP 24mq CNC21915YZ" ];
            resX = 2560; resY = 1440;
          };
        };
      };

    in {
      # NixOS configurations
      nixosConfigurations = {
        "miguel@nitro" = nixpkgs.lib.nixosSystem {
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

        "miguel@framework" = nixpkgs.lib.nixosSystem {
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

        "miguel@vm-shell" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit vars inputs;
            host = vmShellHost;
          };
          modules = [
            nixExperimentalFeatures
            ./hosts/vm-shell/home.nix
          ];
        };
      };
    };
}
