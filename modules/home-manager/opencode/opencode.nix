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
in
{
  home = {
    packages = with pkgs; [
      opencode
      nodejs
      chromium
      docker-client
      ensureChromiumDevtools
      chromiumDevtoolsMcp
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

      "opencode.agents" = {
        source = ./agents;
        target = ".config/opencode/agents";
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
