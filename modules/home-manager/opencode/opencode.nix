{ config, pkgs, lib, ... }:

let
  chromiumDevtoolsHost = "127.0.0.1";
  chromiumDevtoolsPort = 9222;
  chromiumDevtoolsEndpoint = "http://${chromiumDevtoolsHost}:${toString chromiumDevtoolsPort}";
  chromiumDevtoolsProfile = "${config.xdg.dataHome}/opencode/chromium-devtools";
  chromiumDevtoolsService = "opencode-chromium-devtools.service";

  ensureChromiumDevtools = pkgs.writeShellApplication {
    name = "opencode-ensure-chromium-devtools";
    runtimeInputs = [ pkgs.curl pkgs.psmisc ];
    text = ''
      set -euo pipefail

      service=${chromiumDevtoolsService}
      port=${toString chromiumDevtoolsPort}

      ${pkgs.systemd}/bin/systemctl --user start "$service"

      for _ in {1..50}; do
        if ! ${pkgs.systemd}/bin/systemctl --user is-active --quiet "$service"; then
          echo "Managed Chromium service is not active; port $port may already be in use. Inspect: systemctl --user status $service" >&2
          exit 1
        fi

        main_pid="$(${pkgs.systemd}/bin/systemctl --user show --property=MainPID --value "$service")"
        listener_pids="$(${pkgs.psmisc}/bin/fuser -n tcp "$port" 2>/dev/null || true)"
        if [ -z "$listener_pids" ]; then
          sleep 0.2
          continue
        fi

        case " $listener_pids " in
          *" $main_pid "*) ;;
          *)
            echo "DevTools port $port is not owned by managed Chromium (service PID $main_pid; listener PID(s): ''${listener_pids:-none}). Port conflict suspected." >&2
            exit 1
            ;;
        esac

        if ${pkgs.curl}/bin/curl -fsS --max-time 1 \
          ${chromiumDevtoolsEndpoint}/json/version >/dev/null; then
          exit 0
        fi
        sleep 0.2
      done

      echo "Managed Chromium is active but DevTools endpoint did not become ready: ${chromiumDevtoolsEndpoint}/json/version" >&2
      exit 1
    '';
  };

  chromiumDevtoolsMcp = pkgs.writeShellApplication {
    name = "opencode-chromium-devtools-mcp";
    runtimeInputs = with pkgs; [ nodejs ];
    text = ''
      set -euo pipefail

      exec npx -y chrome-devtools-mcp@0.8.0 --browser-url=${chromiumDevtoolsEndpoint}
    '';
  };

  playwrightMcp = pkgs.writeShellApplication {
    name = "opencode-playwright-mcp";
    runtimeInputs = with pkgs; [ nodejs ];
    text = ''
      exec npx -y @playwright/mcp@0.0.78 --cdp-endpoint=${chromiumDevtoolsEndpoint}
    '';
  };

  trivyMcp = pkgs.writeShellApplication {
    name = "opencode-trivy-mcp";
    runtimeInputs = with pkgs; [ gnugrep trivy ];
    text = ''
      set -euo pipefail

      if ! trivy plugin list 2>/dev/null | grep -q '^mcp[[:space:]]'; then
        trivy plugin install mcp
      fi

      exec trivy mcp
    '';
  };

  giteaMcp = pkgs.writeShellApplication {
    name = "opencode-gitea-mcp";
    runtimeInputs = with pkgs; [ coreutils nodejs ];
    text = ''
      set -euo pipefail

      url_file="''${OPENCODE_GITEA_URL_FILE:-/home/miguel/.config/opencode/keys/gitea.url}"
      token_file="''${OPENCODE_GITEA_TOKEN_FILE:-/home/miguel/.config/opencode/keys/gitea.token}"

      if [ ! -r "$url_file" ]; then
        echo "Gitea MCP URL file is missing or unreadable: $url_file" >&2
        exit 1
      fi

      if [ ! -r "$token_file" ]; then
        echo "Gitea MCP token file is missing or unreadable: $token_file" >&2
        exit 1
      fi

      forgejo_url="$(tr -d '\r\n' < "$url_file")"
      forgejo_token="$(tr -d '\r\n' < "$token_file")"

      if [ -z "$forgejo_url" ]; then
        echo "Gitea MCP URL file is empty: $url_file" >&2
        exit 1
      fi

      if [ -z "$forgejo_token" ]; then
        echo "Gitea MCP token file is empty: $token_file" >&2
        exit 1
      fi

      case "$forgejo_url" in
        http://*|https://*) ;;
        *)
          echo "Gitea MCP URL must start with http:// or https://: $url_file" >&2
          exit 1
          ;;
      esac

      token_mode="$(stat -c '%a' "$token_file")"
      if [ $((10#$token_mode % 100)) -ne 0 ]; then
        echo "Gitea MCP token file must not be group/world-readable: $token_file" >&2
        exit 1
      fi

      export FORGEJO_URL="$forgejo_url"
      export FORGEJO_TOKEN="$forgejo_token"
      exec npx -y @ric_/forgejo-mcp@0.1.5
    '';
  };

  trivyDockerScan = pkgs.writeShellApplication {
    name = "trivy-docker-scan";
    runtimeInputs = with pkgs; [ docker-client trivy ];
    text = ''
      set -euo pipefail

      image="''${1:-$(basename "$PWD"):local}"
      context="''${2:-.}"
      severity="''${TRIVY_SEVERITY:-HIGH,CRITICAL}"
      scanners="''${TRIVY_SCANNERS:-vuln,secret,misconfig,license}"

      docker build -t "$image" "$context"
      trivy image \
        --scanners "$scanners" \
        --severity "$severity" \
        --exit-code 1 \
        "$image"
    '';
  };
in
{
  home = {
    packages = with pkgs; [
      opencode
      nodejs
      chromium
      docker-client
      trivy
      ensureChromiumDevtools
      chromiumDevtoolsMcp
      playwrightMcp
      trivyMcp
      giteaMcp
      trivyDockerScan
    ];

    file = {
      "opencode.json" = {
        source = ./opencode.json;
        target = ".config/opencode/opencode.json";
        force = true;
      };

      "opencode.dcp.json" = {
        source = ./dcp.json;
        target = ".config/opencode/dcp.json";
        force = true;
      };

      "opencode.gitignore" = {
        text = ''
          node_modules
          package.json
          package-lock.json
          bun.lock
          .gitignore
        '';
        target = ".config/opencode/.gitignore";
        force = true;
      };

      "opencode.agent-prompts" = {
        source = ./agent-prompts;
        target = ".config/opencode/agent-prompts";
        recursive = true;
        force = true;
      };

      "opencode.commands" = {
        source = ./commands;
        target = ".config/opencode/commands";
        recursive = true;
        force = true;
      };

      "opencode.skills" = {
        source = ./skills;
        target = ".config/opencode/skills";
        recursive = true;
        force = true;
      };

      "opencode.plugins" = {
        source = ./plugins;
        target = ".config/opencode/plugins";
        recursive = true;
        force = true;
      };

    };
  };

  systemd.user.services.opencode-chromium-devtools = {
    Unit = {
      Description = "Chromium DevTools endpoint for OpenCode MCP servers";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.chromium}/bin/chromium --remote-debugging-address=${chromiumDevtoolsHost} --remote-debugging-port=${toString chromiumDevtoolsPort} --user-data-dir=${chromiumDevtoolsProfile} --no-first-run --no-default-browser-check about:blank";
      Restart = "always";
      RestartSec = 2;
      TimeoutStopSec = 10;
    };
  };
}
