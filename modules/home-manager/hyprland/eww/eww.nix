{ pkgs, host, ... }:

{
  home.packages = with pkgs; [
    acpi
    socat
    wirelesstools
    eww
  ];

  xdg.configFile = {
    "eww/eww.yuck".text = builtins.replaceStrings
      [ "EWW_BATTERY.BAT1" ]
      [ "EWW_BATTERY.${host.batteryId}" ]
      (builtins.readFile ./config/eww.yuck);
    "eww/eww.scss".source = ./config/eww.scss;
    "eww/calendar.yuck".source = ./config/calendar.yuck;
    "eww/scripts".source = ./config/scripts;
  };
}
