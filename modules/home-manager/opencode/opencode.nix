{ config, pkgs, lib, ... }:

let
  ensureChromiumDevtools = pkgs.writeShellApplication {
    name = "opencode-ensure-chromium-devtools";
    runtimeInputs = with pkgs; [ curl chromium ];
    text = ''
      set -euo pipefail

      host="''${OPENCODE_DEVTOOLS_HOST:-127.0.0.1}"
      preferred_port="''${OPENCODE_DEVTOOLS_PORT:-9222}"
      debug_ports="''${OPENCODE_DEVTOOLS_PORT_CANDIDATES:-$preferred_port 9223 9224 9225}"
      state_file="''${OPENCODE_DEVTOOLS_STATE_FILE:-/tmp/opencode-chromium-devtools.state}"
      log_file="''${OPENCODE_DEVTOOLS_LOG_FILE:-/tmp/opencode-chromium-devtools.log}"

      if command -v chromium-browser >/dev/null 2>&1; then
        browser_bin="chromium-browser"
      else
        browser_bin="chromium"
      fi

      target_url="''${OPENCODE_DEVTOOLS_URL:-}"
      if [ -z "$target_url" ]; then
        app_host="''${OPENCODE_APP_HOST:-localhost}"
        app_ports="''${OPENCODE_DEVTOOLS_CANDIDATE_PORTS:-5173 4173 3000 4200 8080 8000}"
        for candidate_port in $app_ports; do
          if curl -fsS --max-time 1 "http://$app_host:$candidate_port/" >/dev/null; then
            target_url="http://$app_host:$candidate_port/"
            echo "Detected local dev server at $target_url"
            break
          fi
        done
      fi

      if [ -z "$target_url" ]; then
        target_url="about:blank"
        echo "No local dev server detected. Falling back to $target_url"
      fi

      for debug_port in $debug_ports; do
        endpoint="http://$host:$debug_port/json/version"
        if curl -fsS "$endpoint" >/dev/null; then
          printf 'host=%s\nport=%s\nendpoint=%s\n' "$host" "$debug_port" "$endpoint" > "$state_file"
          echo "Chromium DevTools endpoint already available at $endpoint"
          exit 0
        fi
      done

      profile_dir="''${OPENCODE_DEVTOOLS_PROFILE_DIR:-$(mktemp -d /tmp/opencode-chromium-profile.XXXXXX)}"

      for debug_port in $debug_ports; do
        endpoint="http://$host:$debug_port/json/version"

        echo "No DevTools endpoint found. Launching $browser_bin with remote debugging on $host:$debug_port..."
        printf '\n[%s] Launch command:\n%s --remote-debugging-address=%s --remote-debugging-port=%s --user-data-dir=%s --no-first-run --no-default-browser-check --new-window %s\n' \
          "$(date -Iseconds)" "$browser_bin" "$host" "$debug_port" "$profile_dir" "$target_url" >> "$log_file"

        nohup "$browser_bin" \
          --remote-debugging-address="$host" \
          --remote-debugging-port="$debug_port" \
          --user-data-dir="$profile_dir" \
          --no-first-run \
          --no-default-browser-check \
          --new-window "$target_url" \
          >>"$log_file" 2>&1 &
        launch_pid=$!

        for _ in $(seq 1 50); do
          if curl -fsS "$endpoint" >/dev/null; then
            printf 'host=%s\nport=%s\nendpoint=%s\nprofile=%s\npid=%s\n' "$host" "$debug_port" "$endpoint" "$profile_dir" "$launch_pid" > "$state_file"
            echo "Chromium DevTools endpoint ready at $endpoint"
            exit 0
          fi
          sleep 0.2
        done

        if kill -0 "$launch_pid" >/dev/null 2>&1; then
          kill "$launch_pid" >/dev/null 2>&1 || true
        fi
      done

      echo "Failed to start a debuggable Chromium instance on ports: $debug_ports" >&2
      echo "Check $log_file for launch errors" >&2
      exit 1
    '';
  };

  chromiumDevtoolsMcp = pkgs.writeShellApplication {
    name = "opencode-chromium-devtools-mcp";
    runtimeInputs = with pkgs; [ curl nodejs ];
    text = ''
      set -euo pipefail

      host="''${OPENCODE_DEVTOOLS_HOST:-127.0.0.1}"
      port="''${OPENCODE_DEVTOOLS_PORT:-9222}"
      state_file="''${OPENCODE_DEVTOOLS_STATE_FILE:-/tmp/opencode-chromium-devtools.state}"
      probe_ports="''${OPENCODE_DEVTOOLS_PORT_CANDIDATES:-$port 9223 9224 9225}"

      if [ -z "''${OPENCODE_DEVTOOLS_PORT:-}" ] && [ -f "$state_file" ]; then
        while IFS='=' read -r key value; do
          if [ "$key" = "port" ] && [ -n "$value" ]; then
            port="$value"
            break
          fi
        done < "$state_file"
      fi

      endpoint="http://$host:$port/json/version"
      if ! curl -fsS --max-time 1 "$endpoint" >/dev/null; then
        for probe_port in $probe_ports; do
          probe_endpoint="http://$host:$probe_port/json/version"
          if curl -fsS --max-time 1 "$probe_endpoint" >/dev/null; then
            port="$probe_port"
            break
          fi
        done
      fi

      endpoint="http://$host:$port/json/version"
      if curl -fsS --max-time 1 "$endpoint" >/dev/null; then
        exec npx -y chrome-devtools-mcp@0.8.0 --browser-url="http://$host:$port"
      fi

      exec npx -y chrome-devtools-mcp@0.8.0 \
        --executablePath="${pkgs.chromium}/bin/chromium" \
        --isolated
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

    };
  };
}
