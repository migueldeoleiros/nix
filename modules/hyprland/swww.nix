{ pkgs, ... }:

{
  home.packages = with pkgs; [ swww ];

  # Note: wallpaper.sh is NOT managed by Nix because the wallpaper_menu.sh
  # script needs to modify it dynamically to save per-display wallpaper choices.
  # The file will be created automatically by wallpaper_menu.sh on first use.
  # hyprland.conf exec-once handles: swww-daemon && bash $CONFIG_DIR/wallpaper.sh
}
