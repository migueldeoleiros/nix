{config, pkgs, inputs, vars, ...}:

{
  programs.waybar = {
    enable = true; 
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 25;
        output = [
          "eDP-1"
          "HDMI-A-1"
        ];
        modules-left = [ "clock" "hyprland/workspaces" ];
        modules-right = [ "tray" "network" "pulseaudio" "battery"];
        
        "hyprland/workspaces" = {
          "persistent-workspaces" = {
            "*" = 5;
          };
          "on-click" = "activate";
          "sort-by-number" = true;
          "active-only" = false;
          "all-outputs" = false;
          "format" = "{icon}";
          "format-icons" = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "1";
            "7" = "2";
            "8" = "3";
            "9" = "4";
            "10" = "5";
          };
        };

        "clock"= {
          "interval" = 60;
          "format" = "{:%H:%M}";
          "max-length" = 25;
        };

        "battery" = {
          "interval" = 60;
          "states" = {
            "warning" = 30;
            "critical" = 15;
          };
          "format" = "{capacity}% {icon}";
          "format-icons" = ["" "" "" "" ""];
          "max-length" = 25;
        };

        "tray" = {
          "spacing" = 10;
        };

        "network" = {
          "format" = "{ifname}";
          "format-wifi" = "{essid} ({signalStrength}%) ";
          "format-ethernet" = "{ipaddr}/{cidr} 󰊗";
          "format-disconnected" = "";
          "tooltip-format" = "{ifname} via {gwaddr} 󰊗";
          "tooltip-format-wifi" = "{essid} ({signalStrength}%) ";
          "tooltip-format-ethernet" = "{ifname} ";
          "tooltip-format-disconnected" = "Disconnected";
          "max-length" = 50;
        };

        "pulseaudio" = {
          "format" = "{volume}% {icon}";
          "format-muted" = "";
          "format-icons" = ["" ""];
        };

      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: Source Code Pro;
        font-size: 13;
      }

      window#waybar {
        background: #090a11;
        color: #d4dae8;
      }

      #workspaces button {
        padding: 0 5px;
        color: #afb4c0;
      }        

      #workspaces button.active {
        background-color: #242532;
        color: #d4dae8;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #network,
      #pulseaudio,
      #wireplumber,
      #custom-media,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad,
      #mpd {
        padding: 0 10px;
        color: #d4dae8;
      }

      #tray {
          background-color: #090a11;
      }
      
      #tray > .passive {
          -gtk-icon-effect: dim;
      }
      
      #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background-color: #242532;
      }

    '';

  };
  
}
