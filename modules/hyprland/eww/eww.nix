{ pkgs, ... }:

{
  home.packages = with pkgs; [
    acpi
    socat  # for workspace socket listening
  ];

  programs.eww = {
    enable = true;
    package = pkgs.eww;  # eww-wayland is deprecated
    configDir = ./config;
  };
}
