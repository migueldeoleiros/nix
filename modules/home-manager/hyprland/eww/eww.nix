{ pkgs, ... }:

{
  home.packages = with pkgs; [
    acpi
    socat
    wirelesstools
  ];

  programs.eww = {
    enable = true;
    package = pkgs.eww;
    configDir = ./config;
  };
}
