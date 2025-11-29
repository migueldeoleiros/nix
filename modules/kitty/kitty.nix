{ config, pkgs, lib, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "SauceCodePro Nerd Font";
      size = 12;
    };

    settings = {
      # Cursor
      cursor = "#DDC16E";
      cursor_text_color = "#111111";
      cursor_shape = "beam";
      cursor_beam_thickness = "1.5";
      cursor_underline_thickness = "2.0";
      cursor_blink_interval = "-1";
      cursor_stop_blinking_after = 0;

      # URL
      url_color = "#0087bd";
      url_style = "curly";

      # Bell
      enable_audio_bell = false;
      visual_bell_duration = "0.0";

      # Window
      window_margin_width = 2;
      single_window_margin_width = "-1";
      window_padding_width = 5;
      active_border_color = "#00ff00";
      inactive_border_color = "#cccccc";
      bell_border_color = "#ff5a00";
      inactive_text_alpha = "0.8";
      hide_window_decorations = true;

      # Colors
      foreground = "#e0e0e0";
      background = "#0f0f0f";
      background_opacity = "0.8";
      selection_foreground = "none";
      selection_background = "#4b4b4b";

      # Color table
      color0 = "#191919";
      color8 = "#2d2d2d";
      color1 = "#D2143D";
      color9 = "#D1526D";
      color2 = "#14CC4B";
      color10 = "#57B272";
      color3 = "#DFAD16";
      color11 = "#DDC16E";
      color4 = "#1A63F4";
      color12 = "#7BA3F4";
      color5 = "#EA2EB8";
      color13 = "#EA75CB";
      color6 = "#14B1CC";
      color14 = "#51BACD";
      color7 = "#b9b9b9";
      color15 = "#e0e0e0";

      # Marks
      mark1_foreground = "black";
      mark1_background = "#98d3cb";
      mark2_foreground = "black";
      mark2_background = "#f2dcd3";
      mark3_foreground = "black";
      mark3_background = "#f274bc";

      # Tab bar
      active_tab_foreground = "#000";
      active_tab_background = "#eee";
      active_tab_font_style = "bold-italic";
      inactive_tab_foreground = "#444";
      inactive_tab_background = "#999";
      inactive_tab_font_style = "normal";
      tab_bar_background = "none";
    };
  };
}
