{ config, lib, pkgs, ... }:

# Runs an isolated Chromium profile through a SOCKS tunnel to a remote VM,
# using an external root CA for private services without storing it in Nix.
let
  cfg = config.miguel.vmBrowser;
  serviceName = "vm-browser-socks.service";

  socks = pkgs.writeShellApplication {
    name = "vm-browser-socks";
    runtimeInputs = with pkgs; [ coreutils openssh ];
    text = ''
      set -euo pipefail

      ssh_host_file=${lib.escapeShellArg cfg.sshHostFile}
      if [ ! -r "$ssh_host_file" ]; then
        echo "VM browser SSH host file is missing or unreadable: $ssh_host_file" >&2
        exit 1
      fi

      ssh_host="$(tr -d '\r\n' < "$ssh_host_file")"
      if [ -z "$ssh_host" ]; then
        echo "VM browser SSH host file is empty: $ssh_host_file" >&2
        exit 1
      fi

      exec ssh \
        -N -T \
        -D ${cfg.proxyHost}:${toString cfg.proxyPort} \
        -o UserKnownHostsFile=${lib.escapeShellArg cfg.knownHostsFile} \
        -o BatchMode=yes \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ExitOnForwardFailure=yes \
        -o ConnectTimeout=10 \
        -o ServerAliveInterval=15 \
        -o ServerAliveCountMax=3 \
        "$ssh_host"
    '';
  };

  chromiumLauncher = pkgs.writeShellApplication {
    name = "vm-browser-chromium";
    runtimeInputs = with pkgs; [ chromium coreutils nssTools openssl psmisc systemd ];
    text = ''
      set -euo pipefail
      umask 077

      data_dir=${lib.escapeShellArg cfg.dataDir}
      root_ca_file=${lib.escapeShellArg cfg.rootCaFile}
      fingerprint_file=${lib.escapeShellArg cfg.rootCaFingerprintFile}
      chromium_home="$data_dir/home"
      profile_dir="$data_dir/profile"
      nss_db="$chromium_home/.pki/nssdb"
      ca_nickname="VM Root CA"
      service_started=0
      temp_dir=""

      # shellcheck disable=SC2329
      cleanup() {
        status=$?
        trap - EXIT HUP INT TERM
        if [ "$service_started" -eq 1 ]; then
          if ! systemctl --user stop ${serviceName}; then
            echo "Chromium (VM Proxy): failed to stop ${serviceName}" >&2
            if [ "$status" -eq 0 ]; then
              status=1
            fi
          fi
        fi
        if [ -n "$temp_dir" ]; then
          rm -rf "$temp_dir"
        fi
        exit "$status"
      }
      trap cleanup EXIT
      trap 'exit 129' HUP
      trap 'exit 130' INT
      trap 'exit 143' TERM

      for required_file in "$root_ca_file" "$fingerprint_file"; do
        if [ ! -r "$required_file" ]; then
          echo "VM browser configuration file is missing or unreadable: $required_file" >&2
          exit 1
        fi
      done

      expected_fingerprint="$(tr -d '\r\n' < "$fingerprint_file")"
      actual_fingerprint="$(openssl x509 -in "$root_ca_file" -noout -fingerprint -sha256 | cut -d= -f2)"
      if [ -z "$expected_fingerprint" ] || [ "$actual_fingerprint" != "$expected_fingerprint" ]; then
        echo "Chromium (VM Proxy): root CA fingerprint verification failed" >&2
        exit 1
      fi

      install -d -m 700 "$data_dir" "$chromium_home" "$profile_dir" "$nss_db"
      chmod 700 "$data_dir" "$chromium_home" "$profile_dir" "$nss_db"

      if [ ! -f "$nss_db/cert9.db" ]; then
        certutil -N -d "sql:$nss_db" --empty-password
      fi

      ca_matches=0
      if certutil -L -d "sql:$nss_db" -n "$ca_nickname" >/dev/null 2>&1; then
        temp_dir="$(mktemp -d)"
        certutil -L -d "sql:$nss_db" -n "$ca_nickname" -a -o "$temp_dir/root-ca.pem"
        installed_fingerprint="$(openssl x509 -in "$temp_dir/root-ca.pem" -noout -fingerprint -sha256 | cut -d= -f2)"
        if [ "$installed_fingerprint" = "$actual_fingerprint" ]; then
          ca_matches=1
        fi
      fi
      if [ "$ca_matches" -eq 1 ]; then
        certutil -M -d "sql:$nss_db" -n "$ca_nickname" -t "C,,"
      else
        certutil -D -d "sql:$nss_db" -n "$ca_nickname" >/dev/null 2>&1 || true
        certutil -A -d "sql:$nss_db" -n "$ca_nickname" -t "C,," -i "$root_ca_file"
      fi

      systemctl --user start ${serviceName}
      service_started=1
      for _ in $(seq 1 20); do
        main_pid="$(systemctl --user show --property=MainPID --value ${serviceName})"
        listener_pids="$(fuser -n tcp ${toString cfg.proxyPort} 2>/dev/null || true)"
        for listener_pid in $listener_pids; do
          if [ "$main_pid" != "0" ] && [ "$listener_pid" = "$main_pid" ]; then
            env HOME="$chromium_home" chromium \
              --user-data-dir="$profile_dir" \
              --proxy-server=socks5://${cfg.proxyHost}:${toString cfg.proxyPort} \
              '--proxy-bypass-list=<-loopback>' \
              --disable-quic \
              --force-webrtc-ip-handling-policy=disable_non_proxied_udp \
              --disable-features=DnsOverHttps \
              --no-first-run \
              --no-default-browser-check &
            chromium_pid=$!
            if wait "$chromium_pid"; then
              exit 0
            else
              exit $?
            fi
          fi
        done

        if ! systemctl --user is-active --quiet ${serviceName}; then
          echo "Chromium (VM Proxy): proxy service failed before binding ${cfg.proxyHost}:${toString cfg.proxyPort}" >&2
          exit 1
        fi
        if [ -n "$listener_pids" ]; then
          echo "Chromium (VM Proxy): proxy port is owned by PID(s) $listener_pids, not the managed service (MainPID $main_pid)" >&2
          exit 1
        fi
        sleep 0.5
      done

      echo "Chromium (VM Proxy): proxy service did not bind ${cfg.proxyHost}:${toString cfg.proxyPort}" >&2
      exit 1
    '';
  };
in
{
  options.miguel.vmBrowser = {
    # Keep the SSH target and CA outside Git and the Nix store. Provision this
    # private directory with mode 0700 and its files with mode 0600.
    sshHostFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/vm-browser/private/ssh-host";
      description = "Runtime file containing the SSH host or alias used for the SOCKS tunnel.";
    };

    knownHostsFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.ssh/known_hosts";
      description = "SSH known-hosts file used by the tunnel.";
    };

    rootCaFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/vm-browser/private/root-ca.pem";
      description = "Runtime path to the root CA imported into the isolated browser profile.";
    };

    rootCaFingerprintFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/vm-browser/private/root-ca.sha256";
      description = "Runtime file containing the expected SHA-256 certificate fingerprint.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/vm-browser/chromium";
      description = "Directory for the isolated Chromium home and profile.";
    };

    proxyHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Local address for the SOCKS proxy.";
    };

    proxyPort = lib.mkOption {
      type = lib.types.port;
      default = 1080;
      description = "Local port for the SOCKS proxy.";
    };
  };

  config = {
    systemd.user.services.vm-browser-socks = {
      Unit.Description = "SOCKS proxy through a browser VM";
      Service = {
        Type = "exec";
        ExecStart = "${socks}/bin/vm-browser-socks";
      };
    };

    home.packages = [ chromiumLauncher ];

    xdg.desktopEntries.vm-browser-chromium = {
      name = "Chromium (VM Proxy)";
      exec = "${chromiumLauncher}/bin/vm-browser-chromium";
      terminal = false;
      type = "Application";
      categories = [ "Network" ];
    };
  };
}
