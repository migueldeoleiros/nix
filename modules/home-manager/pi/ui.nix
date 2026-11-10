{ config, lib, pkgs, ... }:
let
  choices = import ./config/extensions.nix;
  contextView = pkgs.callPackage ../../../pkgs/pi-context-view.nix { };
  visor = pkgs.callPackage ../../../pkgs/pi-visor.nix { };
  profileFiles = profile:
    lib.optionalAttrs choices.contextView {
      "pi-${profile}.ui.context-view" = {
        source = "${contextView}/lib/node_modules/pi-context-view";
        target = ".config/pi-${profile}/extensions/pi-context-view";
        force = true;
      };
    } // lib.optionalAttrs choices.visor {
      "pi-${profile}.ui.visor" = {
        source = "${visor}/lib/node_modules/pi-visor";
        target = ".config/pi-${profile}/extensions/pi-visor";
        force = true;
      };
    };
in {
  home.file = builtins.foldl' (files: profile: files // profileFiles profile) { }
    config.miguel.pi.enabledProfiles;
}
