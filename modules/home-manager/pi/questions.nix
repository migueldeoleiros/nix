{ config, lib, pkgs, ... }:

let
  choices = import ./config/extensions.nix;
  askerPackage = pkgs.callPackage ../../../pkgs/pi-asker.nix { };
  askerRoot = "${askerPackage}/lib/node_modules/pi-asker";
  profileFiles = lib.concatMap (profile:
    let root = ".config/pi-${profile}";
    in lib.optional choices.asker {
        name = "pi-${profile}.asker-extension";
        value = {
          source = askerRoot;
          target = "${root}/extensions/pi-asker";
          recursive = true;
          force = true;
        };
      }
    ) config.miguel.pi.enabledProfiles;
in
{
  home.file = lib.listToAttrs profileFiles;
}
