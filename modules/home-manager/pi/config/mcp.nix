{ hrMerlinContextEnabled ? false, agentSecretsPackage ? null, pkgs ? null, lib ? null }:
let
  hrAuthorization = "!${lib.escapeShellArg "${pkgs.bash}/bin/bash"} -c ${lib.escapeShellArg ''token="$(${agentSecretsPackage}/bin/agent-secrets read --trim-eol hr-merlin-context-token)" || exit 1; [ -n "$token" ] || exit 1; printf 'Bearer %s' "$token"''}";
in {
  context7 = {
    url = "https://mcp.context7.com/mcp";
    description = "Fetch current library documentation";
    exposure = "codemode";
  };
  codegraph = {
    args = [ ];
    description = "Read-only code graph MCP server; indexing remains explicit";
    exposure = "codemode";
  };
  engram = {
    args = [ ];
    description = "Pi-profile-local Engram memory; not shared with OpenCode";
    exposure = "codemode";
  };
} // (if hrMerlinContextEnabled then {
  "hr-merlin-context" = {
    url = "https://hr-api.merlinsoftware.es/mcp";
    headers.Authorization = hrAuthorization;
    description = "Merlin HR context (optional; connection fails when its credential is unavailable)";
    exposure = "codemode";
  };
} else {})
