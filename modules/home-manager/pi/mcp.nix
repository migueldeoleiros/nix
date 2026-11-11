{ config, pkgs, lib, ... }:
let
  cfg = config.miguel.pi;
  agentSecrets = config.miguel.agentSecrets.package;
  hrMerlinContextEnabled = config.miguel.opencode.hrMerlinContext.enable or false;
  mcpConfig = profile: import ./config/mcp.nix {
    hrMerlinContextEnabled = profile == "merlin" && hrMerlinContextEnabled;
    inherit pkgs lib;
    agentSecretsPackage = agentSecrets;
  };
  giteaMcp = pkgs.writeShellApplication {
    name = "pi-gitea-mcp";
    runtimeInputs = with pkgs; [ coreutils nodejs ];
    text = ''
      set -euo pipefail
      set +x
      forgejo_url="$(${agentSecrets}/bin/agent-secrets read --trim-eol gitea-url)"
      forgejo_token="$(${agentSecrets}/bin/agent-secrets read --trim-eol gitea-token)"
      if [ -z "$forgejo_url" ]; then
        echo "Gitea MCP URL is empty in the keyring" >&2
        exit 1
      fi
      case "$forgejo_url" in
        http://*|https://*) ;;
        *) echo "Gitea MCP URL must start with http:// or https://" >&2; exit 1 ;;
      esac
      export FORGEJO_URL="$forgejo_url" FORGEJO_TOKEN="$forgejo_token"
      exec npx -y @ric_/forgejo-mcp@0.1.5
    '';
  };
  sonarqubeMcp = pkgs.writeShellApplication {
    name = "pi-sonarqube-mcp";
    runtimeInputs = with pkgs; [ coreutils docker-client ];
    text = ''
      set +x
      SONARQUBE_URL="$(${agentSecrets}/bin/agent-secrets read --trim-eol sonarqube-url)"
      case "$SONARQUBE_URL" in
        http://*|https://*) ;;
        *) echo "SonarQube MCP URL must start with http:// or https://" >&2; exit 1 ;;
      esac
      SONARQUBE_TOKEN="$(${agentSecrets}/bin/agent-secrets read --trim-eol sonarqube-token)"
      export SONARQUBE_URL SONARQUBE_TOKEN
      exec docker run --init --rm --network=host -i -e SONARQUBE_TOKEN -e SONARQUBE_URL mcp/sonarqube
    '';
  };
  trivyMcp = pkgs.writeShellApplication {
    name = "pi-trivy-mcp";
    runtimeInputs = with pkgs; [ gnugrep trivy ];
    text = ''
      set -euo pipefail
      if ! trivy plugin list 2>/dev/null | grep -q '^mcp[[:space:]]'; then
        trivy plugin install mcp
      fi
      exec trivy mcp
    '';
  };
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
  _module.args.piMcpConfig = profile:
    let profileMcpConfig = mcpConfig profile;
    in {
    mcpServers = profileMcpConfig // (lib.optionalAttrs (profile == "merlin") {
      gitea = {
        command = "${giteaMcp}/bin/pi-gitea-mcp";
        args = [ ];
        description = "Gitea repository management";
        exposure = "codemode";
      };
      sonarqube = {
        command = "${sonarqubeMcp}/bin/pi-sonarqube-mcp";
        args = [ ];
        description = "SonarQube analysis";
        exposure = "codemode";
      };
      trivy = {
        command = "${trivyMcp}/bin/pi-trivy-mcp";
        args = [ ];
        description = "Trivy security scanning";
        timeout = 120;
        exposure = "codemode";
      };
    }) // {
      codegraph = profileMcpConfig.codegraph // { command = "${codegraphMcp}/bin/pi-codegraph-mcp"; };
      engram = profileMcpConfig.engram // { command = "${engramMcp profile}/bin/pi-engram-${profile}-mcp"; };
    };
  };
}
