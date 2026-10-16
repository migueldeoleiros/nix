{ pkgs, lib }:

profile:
let
  codegraphPackage = pkgs.codegraph;
  wrapper = pkgs.writeShellApplication {
    name = "codegraph-${profile}-mcp";
    runtimeInputs = [ codegraphPackage ];
    text = ''
      # Telemetry opt-out: DO_NOT_TRACK is honored by codegraph's telemetry
      # module (resolution order: DO_NOT_TRACK=1 > CODEGRAPH_TELEMETRY).
      # CODEGRAPH_NO_UPDATE_CHECK disables the 24h update check; DO_NOT_TRACK
      # also disables it as a fallback.
      export DO_NOT_TRACK=1
      export CODEGRAPH_NO_UPDATE_CHECK=1

      # Do not implicitly initialize or index projects. The wrapper only starts
      # the MCP server; indexing is left to explicit `codegraph init` per
      # workspace.
      exec codegraph serve --mcp "$@"
    '';
  };
in
{
  inherit codegraphPackage wrapper;

  mcp = {
    type = "local";
    disabled = false;
    command = [ "${wrapper}/bin/codegraph-${profile}-mcp" ];
    timeout = { catalog = 60000; execution = 60000; };
  };
}
