{ config, pkgs, vars, ... }:

{
  programs = {
    rofi.enable = true;
    rofi.theme = ./themes/SimpleIconCenter.rasi;
  };
}
