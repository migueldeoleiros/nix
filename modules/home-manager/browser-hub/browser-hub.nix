{ lib, pkgs, ... }:

# One shared agent-browser instance for all agent sessions, in a rootless, non-root Podman container.
# The live viewer/takeover dashboard is published on host loopback only; `browser-hub` runs agent-browser
# commands inside it with one named session and profile per working directory.
let
  name = "browser-hub";
  uid = "10001";
  viewerPort = "4848"; # dashboard, host loopback
  pwaPort = "4850"; # installable-PWA front for the dashboard, host loopback

  entry = pkgs.writeShellApplication {
    name = "${name}-entry";
    runtimeInputs = with pkgs; [ agent-browser socat procps coreutils ];
    text = ''
      mkdir -p "$HOME" /data
      # Stale Chromium profile locks survive container recreation; clear only when no Chrome runs.
      if ! pgrep -x chromium >/dev/null; then rm -f /data/profile-*/Singleton* 2>/dev/null || true; fi
      agent-browser dashboard start
      # The dashboard binds container loopback only; bridge it for the published port.
      exec socat TCP-LISTEN:4849,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:4848
    '';
  };

  image = pkgs.dockerTools.buildLayeredImage {
    inherit name;
    tag = "latest";
    contents = with pkgs; [ entry agent-browser chromium socat procps coreutils bashInteractive cacert fontconfig dejavu_fonts ];
    extraCommands = "mkdir -p tmp data && chmod 1777 tmp";
    config = {
      User = "${uid}:${uid}";
      Entrypoint = [ "${entry}/bin/${name}-entry" ];
      Env = [
        "HOME=/data/home"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "AGENT_BROWSER_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium"
        # Rootless Podman's seccomp profile blocks Chromium's own user-namespace sandbox; the container is the boundary.
        "AGENT_BROWSER_ARGS=--no-sandbox"
        "FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
      ];
    };
  };

  podman = "${pkgs.podman}/bin/podman";

  # Host-side convenience: run agent-browser in the hub under this directory's own session/profile.
  cli = pkgs.writeShellApplication {
    name = name;
    runtimeInputs = [ pkgs.podman pkgs.coreutils ];
    text = ''
      session="''${AGENT_BROWSER_SESSION:-$(basename "$PWD" | tr -c 'A-Za-z0-9_-' '_')}"
      exec podman exec -i -e "AGENT_BROWSER_SESSION=$session" ${name} \
        agent-browser --profile "/data/profile-$session" "$@"
    '';
  };

  nginxConf = pkgs.writeText "${name}-pwa.conf" ''
    daemon off;
    pid /tmp/${name}-pwa/nginx.pid;
    error_log stderr;
    events {}
    http {
      access_log off;
      client_body_temp_path /tmp/${name}-pwa/body;
      proxy_temp_path /tmp/${name}-pwa/proxy;
      fastcgi_temp_path /tmp/${name}-pwa/fcgi;
      uwsgi_temp_path /tmp/${name}-pwa/uwsgi;
      scgi_temp_path /tmp/${name}-pwa/scgi;
      map $http_upgrade $connection_upgrade { default upgrade; "" close; }
      server {
        listen 127.0.0.1:${pwaPort};
        location = /manifest.webmanifest {
          default_type application/manifest+json;
          return 200 '{"name":"Browser Hub","short_name":"Browser Hub","start_url":"/","scope":"/","display":"standalone","background_color":"#111111","theme_color":"#111111","icons":[{"src":"/pwa-icon.svg","sizes":"any","type":"image/svg+xml","purpose":"any"}]}';
        }
        location = /pwa-icon.svg {
          default_type image/svg+xml;
          return 200 '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" rx="12" fill="#111"/><circle cx="32" cy="32" r="18" fill="none" stroke="#4ea1ff" stroke-width="4"/><path d="M14 32h36M32 14c8 9 8 27 0 36M32 14c-8 9-8 27 0 36" fill="none" stroke="#4ea1ff" stroke-width="3"/></svg>';
        }
        location = /sw.js {
          default_type application/javascript;
          return 200 'self.addEventListener("fetch",function(){});';
        }
        location / {
          proxy_pass http://127.0.0.1:${viewerPort};
          proxy_http_version 1.1;
          proxy_set_header Host 127.0.0.1:${viewerPort};
          proxy_set_header Origin http://127.0.0.1:${viewerPort};
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection $connection_upgrade;
          proxy_set_header Accept-Encoding "";
          proxy_read_timeout 1d;
          sub_filter '</head>' '<link rel="manifest" href="/manifest.webmanifest"><script>navigator.serviceWorker&&navigator.serviceWorker.register("/sw.js")</script></head>';
          sub_filter_once on;
        }
      }
    }
  '';
in
{
  home.packages = [ cli ];

  systemd.user.services.${name} = {
    Unit = {
      Description = "Shared agent-browser instance (rootless Podman)";
      After = [ "podman.socket" ];
    };
    Service = {
      Type = "simple";
      # newuidmap/newgidmap come from the NixOS setuid wrappers.
      Environment = [ "PATH=/run/wrappers/bin:${lib.makeBinPath [ pkgs.podman pkgs.coreutils pkgs.shadow ]}" ];
      ExecStartPre = [
        "-${podman} rm -f -t 10 ${name}"
        "${podman} load -i ${image}"
      ];
      ExecStart = lib.concatStringsSep " " [
        "${podman} run --rm --name ${name} --init"
        "--security-opt no-new-privileges --cap-drop ALL"
        "-p 127.0.0.1:${viewerPort}:4849"
        "-v ${name}-data:/data:U"
        "localhost/${name}:latest"
      ];
      ExecStop = "${podman} stop -t 20 ${name}";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 40;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services."${name}-pwa" = {
    Unit = {
      Description = "Installable-PWA front for the browser-hub viewer";
      After = [ "${name}.service" ];
      Wants = [ "${name}.service" ];
    };
    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /tmp/${name}-pwa";
      ExecStart = "${pkgs.nginx}/bin/nginx -p /tmp/${name}-pwa -e /dev/stderr -c ${nginxConf}";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
