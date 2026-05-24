{ pkgs, host, lib, ... }:

let
  toLua = builtins.toJSON;
in
{
  home = {
    packages = with pkgs; [
      # Display/input utilities
      brightnessctl
      playerctl
      wayshot
      slurp

      # Wayland/Qt integration
      libva
      libsForQt5.qt5ct

      # Hyprland ecosystem
      pyprland
      hyprshutdown
      hyprlock
      wl-clipboard
      bibata-cursors
      polkit_gnome

      # Script dependencies
      jq
      procps
      gnused
      coreutils
      gawk
      alsa-utils
      unixtools.ifconfig
    ];

    file = {
      ".config/pypr/config.toml".source = ./pyprland.toml;
      ".config/hypr/hyprlock.conf".source = ./hyprlock.conf;
      ".config/hypr/scripts".source = ./scripts;

      # Screen configuration (individual files since variables are generated)
      ".config/hypr/screen_conf/screen_on_right.lua".source = ./screen_conf/screen_on_right.lua;
      ".config/hypr/screen_conf/screen_on_left.lua".source = ./screen_conf/screen_on_left.lua;
      ".config/hypr/screen_conf/mirror.lua".source = ./screen_conf/mirror.lua;
      ".config/hypr/screen_conf/custom_three.lua".source = ./screen_conf/custom_three.lua;

      # Generated per-host config
      ".config/hypr/hyprland-host.lua".text = ''
        -- Host-specific config for ${host.hostName}
        function start_host_services()
            hl.exec_cmd(${toLua "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"})
        end
      '' + lib.optionalString host.hasNvidia ''
        hl.env("LIBVA_DRIVER_NAME", "nvidia")
        hl.env("__GL_GSYNC_ALLOWED", "0")
        hl.env("__GL_VRR_ALLOWED", "0")
        hl.env("WLR_DRM_NO_ATOMIC", "1")
      '' + ''
        hl.config({
            input = {
                tablet = {
                    output = ${toLua host.tabletOutput},
                },
            },
        })
      '';

      ".config/hypr/screen_conf/variables.lua" = {
        force = true;
        text = ''
          A_MONITOR = ${toLua host.monitors.a.name} -- laptop
          A_RES_X = ${toLua (toString host.monitors.a.resX)}
          A_RES_Y = ${toLua (toString host.monitors.a.resY)}
          A_SCALE = ${host.monitors.a.scale}

          B_MONITOR = ${toLua host.monitors.b.name}
          B_RES_X = ${toLua (toString host.monitors.b.resX)}
          B_RES_Y = ${toLua (toString host.monitors.b.resY)}

          C_MONITOR = ${toLua host.monitors.c.name}

          KEYBOARD_LAYOUT = ${toLua host.keyboard.layout}
          KEYBOARD_VARIANT = ${toLua host.keyboard.variant}
          KEYBOARD_OPTIONS = ${toLua host.keyboard.options}
        '';
      };
    };
  };

  # Create default screen config if missing (mutable at runtime via screen_config.sh)
  home.activation.createDefaultScreenConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SCREEN_LUA="$HOME/.config/hypr/screen_conf/screen.lua"
    mkdir -p "$(dirname "$SCREEN_LUA")"

    DEFAULT_SCREEN="${lib.removeSuffix ".conf" host.defaultScreenConfig}.lua"

    if ! grep -q 'screen_conf/.*\.lua' "$SCREEN_LUA" 2>/dev/null || ! sed -n 's/.*screen_conf\/\([^"'"'"']*\.lua\).*/\1/p' "$SCREEN_LUA" | head -n1 | xargs -r -I{} test -e "$HOME/.config/hypr/screen_conf/{}"; then
      echo "dofile(os.getenv(\"HOME\") .. \"/.config/hypr/screen_conf/$DEFAULT_SCREEN\")" > "$SCREEN_LUA"
    fi
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    configType = "lua";
    extraConfig = ''
      dofile(os.getenv("HOME") .. "/.config/hypr/hyprland-main.lua")
    '';
  };

  xdg.configFile."hypr/hyprland-main.lua".source = ./hyprland.lua;
}
