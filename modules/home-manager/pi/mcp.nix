{ config, pkgs, lib, ... }:
let
  cfg = config.miguel.pi;
  mcpConfig = import ./config/mcp.nix;
  render = source: keys: values: builtins.replaceStrings keys values source;
  engramPackage = pkgs.callPackage ../../../pkgs/engram.nix { };
  engramMcp = profile: pkgs.writeShellApplication {
    name = "pi-engram-${profile}-mcp";
    runtimeInputs = [ engramPackage pkgs.git ];
    text = render (builtins.readFile ./scripts/engram-mcp.sh)
      [ "@ENGRAM_DATA_DIR@" "@ENGRAM_EXE@" ]
      [ (lib.escapeShellArg "${config.xdg.dataHome}/pi-engram/${profile}") (lib.escapeShellArg "${engramPackage}/bin/engram") ];
  };
  codegraphMcp = pkgs.writeShellApplication {
    name = "pi-codegraph-mcp";
    runtimeInputs = [ pkgs.codegraph ];
    text = builtins.readFile ./scripts/codegraph-mcp.sh;
  };
in {
  home.packages = [ codegraphMcp ];
  _module.args.piMcpConfig = profile: {
    mcpServers = mcpConfig // {
      codegraph = mcpConfig.codegraph // { command = "${codegraphMcp}/bin/pi-codegraph-mcp"; };
      engram = mcpConfig.engram // { command = "${engramMcp profile}/bin/pi-engram-${profile}-mcp"; };
    };
  };
}
