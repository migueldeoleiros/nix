{ pkgs, ... }:

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
      hyprlock
      wl-clipboard
      cliphist

      # Script dependencies
      jq
      procps
      gnused
      coreutils
      gawk
    ];

    file = {
      # Main hyprland config
      ".config/hypr/hyprland.conf".source = ./hyprland.conf;

      # Pyprland config
      ".config/hypr/pyprland.toml".source = ./pyprland.toml;

      # Screen configuration directory
      ".config/hypr/screen_conf".source = ./screen_conf;

      # Power menu script
      ".config/hypr/scripts/power_menu.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash

          rofi_cmd(){
              rofi \
              -theme-str 'window {width: 300px; height: 300px;}' \
              -dmenu -i \
              -p "POWER MENU"
          }

          selection=$(echo -e "Poweroff\nReboot\nLock Screen\nExit Hyprland\n" | rofi_cmd)

          case $selection in
              "Poweroff") poweroff ;;
              "Reboot") reboot ;;
              "Lock Screen") hyprlock ;;
              "Exit Hyprland") killall Hyprland ;;
          esac
        '';
      };

      # Open bar script - opens correct eww bar based on monitor count
      ".config/hypr/scripts/open_bar.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash

          # Open bar in the main monitor
          # If there is only one screen open bar in that one, if there is 2 or more open it in the second one

          num_monitors=$(hyprctl -j monitors | jq '. | length')

          if [ "$num_monitors" -ge 2 ]; then
              eww open bar-main
          else
              eww open bar-laptop
          fi
        '';
      };

      # Wallpaper menu script
      ".config/hypr/scripts/wallpaper_menu.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash

          wallpaper_dir="$HOME/wallpapers"
          wallpaper_script="$HOME/.config/hypr/wallpaper.sh"
          transition="center"

          rofi_cmd(){
              rofi \
              -theme-str 'window {width: 500; height: 500;}' \
              -dmenu -i \
              -p "SELECT WALLPAPER"
          }

          get_selection(){
              local dir_file="$1"

              if [[ -d $dir_file ]]; then
                  selected=$(ls "$dir_file" | rofi_cmd)
                  if [[ "$selected" == "" ]]; then
                      echo ""
                  else
                      get_selection "$dir_file/$selected"
                  fi
              elif [[ -f $dir_file ]]; then
                  echo "$dir_file"
              else
                  echo ""
              fi
          }

          selection=$(get_selection "$wallpaper_dir")
          display=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
          display_line=$(grep -n "$display" "$wallpaper_script" 2>/dev/null | cut -d: -f1)

          if [[ -n $selection ]]; then
              swww img "$selection" --transition-type "$transition" -o "$display"
              if [[ -z $display_line ]]; then
                  echo "swww img $selection -o $display" >> "$wallpaper_script"
              else
                  sed -i "''${display_line}s|.*|swww img $selection -o $display|" "$wallpaper_script"
              fi
              chmod +x "$wallpaper_script"
          fi
        '';
      };

      # Screen config menu script
      ".config/hypr/scripts/screen_config.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash

          CONFIG_DIR="$HOME/.config/hypr/screen_conf"

          declare -A OPTIONS=(
            ["Custom Three Monitors"]="custom_three.conf"
            ["Mirror Display"]="mirror.conf"
            ["Screen on Left"]="screen_on_left.conf"
            ["Screen on Right"]="screen_on_right.conf"
          )

          SELECTED_TEXT=$(printf "%s\n" "''${!OPTIONS[@]}" | rofi -dmenu -p "Select screen configuration:")

          if [[ -n "$SELECTED_TEXT" ]]; then
            SELECTED_FILE="''${OPTIONS[$SELECTED_TEXT]}"
            SOURCE_LINE="source = $CONFIG_DIR/$SELECTED_FILE"
            echo "$SOURCE_LINE" > "$CONFIG_DIR/screen.conf"
          fi
        '';
      };

      # Kill menu script
      ".config/hypr/scripts/kill_menu.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash

          program=$(ps -u "$USER" -o comm,pid | awk 'NR > 1' | rofi -dmenu -i -p "kill")
          pid=$(echo "$program" | awk '{print $NF}')
          if [[ -n "$pid" ]]; then
              kill "$pid"
          fi
        '';
      };

      # Swap workspace monitor script
      ".config/hypr/scripts/swap_workspace_monitor.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash

          # Simple script that moves hyprland workspaces around connected monitors

          MONITORS=$(hyprctl monitors -j | jq -r '.[] | .id')
          CURRENT=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .id')
          INDEX=$(echo "$MONITORS" | tr ' ' '\n' | grep -n "$CURRENT" | cut -d: -f1)
          NEXT_INDEX=$(( (INDEX) % $(echo "$MONITORS" | wc -w) ))
          NEXT_MONITOR=$(echo "$MONITORS" | tr ' ' '\n' | head -n $((NEXT_INDEX + 1)) | tail -n 1)
          hyprctl dispatch movecurrentworkspacetomonitor "$NEXT_MONITOR"
        '';
      };

      # Focus window script (emacs-like buffer switching)
      ".config/hypr/scripts/hypr_focus_window.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash

          # Get a list of windows in hyprland and select one to move focus
          # Inspired to work similar to emacs buffers

          clients=$(hyprctl -j clients)

          window=$(echo "$clients" |
              jq -r '.[] | select(.class != "" ) | "[\(.workspace.name)] \(.class) - \(.title)"' |
              sort |
              rofi -dmenu -i -p "Select window")

          if [[ -n "$window" ]]; then
              address=$(echo "$clients" |
                  jq -r --arg win "$window" '.[] | select(.class != "" and "[\(.workspace.name)] \(.class) - \(.title)" == $win) | .address')
              hyprctl dispatch focuswindow "address:$address"
          fi
        '';
      };

      # Mirror toggle script
      ".config/hypr/scripts/mirror_toggle.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash

          # Simple script that toggles a commented line for switching between extending or sharing screen

          FILE="$HOME/.config/hypr/hyprland.conf"
          LINE_NUMBER=5

          if sed -n "''${LINE_NUMBER}p" "$FILE" | grep -q '^#'; then
            sed -i "''${LINE_NUMBER}s/^#//" "$FILE"
          else
            sed -i "''${LINE_NUMBER}s/^/#/" "$FILE"
          fi
        '';
      };
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
}
