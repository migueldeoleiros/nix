{ config, pkgs, lib }:

let
  engramPackage = pkgs.callPackage ../../../pkgs/engram.nix { };
in

profile:
let
  dataDir = "${config.xdg.dataHome}/opencode-engram/${profile}";
  wrapper = pkgs.writeShellApplication {
    name = "engram-${profile}-mcp";
    runtimeInputs = [ engramPackage pkgs.git ];
    text = ''
      unset ENGRAM_URL
      unset ENGRAM_PROJECT
      unset ENGRAM_CLOUD_SERVER
      unset ENGRAM_CLOUD_TOKEN

      export ENGRAM_DATA_DIR=${lib.escapeShellArg dataDir}
      export ENGRAM_NO_UPDATE_CHECK=1
      export ENGRAM_CLOUD_AUTOSYNC=0

      exec ${engramPackage}/bin/engram mcp --tools=agent "$@"
    '';
  };
in
{
  inherit engramPackage dataDir wrapper;
  mcp = {
    type = "local";
    enabled = true;
    command = [ "${wrapper}/bin/engram-${profile}-mcp" ];
    timeout = 60000;
  };
}
