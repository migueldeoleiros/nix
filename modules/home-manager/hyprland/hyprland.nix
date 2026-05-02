{ pkgs, host, lib, ... }:

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
      cliphist
      networkmanager_dmenu
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
      ".config/hypr/hyprland-settings.conf".source = ./hyprland.conf;
      ".config/pypr/config.toml".source = ./pyprland.toml;
      ".config/hypr/hyprlock.conf".source = ./hyprlock.conf;
      ".config/hypr/scripts".source = ./scripts;

      # Screen configuration (individual files since variables.conf is generated)
      ".config/hypr/screen_conf/screen_on_right.conf".source = ./screen_conf/screen_on_right.conf;
      ".config/hypr/screen_conf/screen_on_left.conf".source = ./screen_conf/screen_on_left.conf;
      ".config/hypr/screen_conf/mirror.conf".source = ./screen_conf/mirror.conf;
      ".config/hypr/screen_conf/custom_three.conf".source = ./screen_conf/custom_three.conf;

      # Generated per-host config
      ".config/hypr/hyprland-host.conf".text = ''
        # Host-specific config for ${host.hostName}
        exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      '' + lib.optionalString host.hasNvidia ''
        env = LIBVA_DRIVER_NAME,nvidia
        env = __GL_GSYNC_ALLOWED,0
        env = __GL_VRR_ALLOWED,0
        env = WLR_DRM_NO_ATOMIC,1
      '' + ''
        input {
            tablet {
                output = ${host.tabletOutput}
            }
        }
      '';

      ".config/hypr/screen_conf/variables.conf" = {
        force = true;
        text = ''
          $A_MONITOR = ${host.monitors.a.name} # laptop
          $A_RES_X = ${toString host.monitors.a.resX}
          $A_RES_Y = ${toString host.monitors.a.resY}

          $B_MONITOR = ${host.monitors.b.name}
          $B_RES_X = ${toString host.monitors.b.resX}
          $B_RES_Y = ${toString host.monitors.b.resY}

          $C_MONITOR = ${host.monitors.c.name}
        '';
      };
    };
  };

  # Create default screen.conf if missing (mutable at runtime via screen_config.sh)
  home.activation.createDefaultScreenConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SCREEN_CONF="$HOME/.config/hypr/screen_conf/screen.conf"
    if [ ! -f "$SCREEN_CONF" ]; then
      mkdir -p "$(dirname "$SCREEN_CONF")"
      echo "source = $HOME/.config/hypr/screen_conf/${host.defaultScreenConfig}" > "$SCREEN_CONF"
    fi
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    extraConfig = ''
      source = ~/.config/hypr/hyprland-settings.conf
    '';
  };
}
