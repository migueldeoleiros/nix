{ pkgs, ... }:

{
  home.packages = with pkgs; [
    acpi
    socat
  ];

  programs.eww = {
    enable = true;
    package = pkgs.eww;
    configDir = ./config;
  };
}
