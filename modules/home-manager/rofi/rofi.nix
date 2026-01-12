{ config, pkgs, vars, ... }:

{
  programs.rofi = {
    enable = true;
    theme = ./themes/SimpleIconCenter.rasi;
    plugins = [ pkgs.rofi-calc ];
  };
}
