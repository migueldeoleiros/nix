{ config, lib, pkgs, ... }:

let
  # Handy's recommended multilingual model; runs locally on either host's CPU.
  # Unlike Parakeet V2, V3 supports both Spanish and English automatically.
  modelArchive = pkgs.fetchurl {
    url = "https://blob.handy.computer/parakeet-v3-int8.tar.gz";
    hash = "sha256-Q9NxkWAnJ1JKfYxtoO7xHEuiQyD1tHMPGiSXvvwu+nc=";
  };
  model = pkgs.runCommand "handy-parakeet-v3-int8" { } ''
    mkdir -p "$out"
    tar --extract --gzip --file=${modelArchive} --directory="$out" \
      --strip-components=1 --exclude='*/._*' --warning=no-unknown-keyword
  '';
  initialSettings = pkgs.writeText "handy-settings.json" (builtins.toJSON {
    settings = {
      selected_model = "parakeet-tdt-0.6b-v3";
      selected_language = "auto";
      translate_to_english = false;
      post_process_enabled = false;
      onboarding_completed = true;
      shortcut_activation = "toggle";
      start_hidden = true;
      autostart_enabled = false; # Managed by the user service below.
      update_checks_enabled = false; # Updates come from nixpkgs.
      paste_method = "direct";
      typing_tool = "wtype";
    };
  });
  configure = pkgs.writeShellApplication {
    name = "handy-configure";
    runtimeInputs = [ pkgs.coreutils pkgs.jq ];
    text = ''
      settings_dir="${config.xdg.dataHome}/com.pais.handy"
      settings_file="$settings_dir/settings_store.json"
      mkdir -p "$settings_dir"
      temporary=$(mktemp "$settings_dir/.settings.XXXXXX")
      trap 'rm -f "$temporary"' EXIT
      if [ -s "$settings_file" ]; then
        jq -e --slurpfile defaults ${initialSettings} \
          '. * $defaults[0]' "$settings_file" > "$temporary"
      else
        cp ${initialSettings} "$temporary"
      fi
      test -s "$temporary"
      chmod 600 "$temporary"
      mv "$temporary" "$settings_file"
    '';
  };
in
{
  home.packages = [ pkgs.handy pkgs.wtype pkgs.wl-clipboard ];

  xdg.dataFile."com.pais.handy/models/parakeet-tdt-0.6b-v3-int8".source = model;

  # Handy needs a writable store. Merge managed defaults before startup,
  # preserving microphone choices, bindings and other unrelated preferences.
  # Activation only seeds missing stores, so a running app cannot race a merge.
  home.activation.handySettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ ! -e "${config.xdg.dataHome}/com.pais.handy/settings_store.json" ]; then
      ${lib.getExe configure}
    fi
  '';

  systemd.user.services.handy = {
    Unit = {
      Description = "Handy local speech-to-text";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStartPre = "${lib.getExe configure}";
      ExecStart = "${lib.getExe pkgs.handy} --start-hidden";
      Environment = "PATH=${lib.makeBinPath [ pkgs.wtype pkgs.wl-clipboard pkgs.coreutils pkgs.which ]}:/run/current-system/sw/bin";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Trigger on release; release Super too before transcription types the text.
  # Press once to record, again to stop/transcribe/type. Only these two hosts.
  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    hl.bind("SUPER + X", hl.dsp.exec_cmd("${lib.getExe pkgs.handy} --toggle-transcription"), { release = true })
  '';
}
