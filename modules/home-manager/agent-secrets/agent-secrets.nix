{ config, lib, pkgs, ... }:
let
  cfg = config.miguel.agentSecrets;
in {
  options.miguel.agentSecrets = {
    enable = lib.mkEnableOption "curated desktop credentials for agent applications";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "Credential enrollment and fixed-consumer helper package.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package pkgs.seahorse ];
  };
}
