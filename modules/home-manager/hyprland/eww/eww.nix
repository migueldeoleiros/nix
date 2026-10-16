{ pkgs, host, ... }:

let
  notificationScript = pkgs.writeShellScript "eww-notifications" ''
    toggle() {
      dunstctl set-paused toggle
    }

    state() {
      paused=$(dunstctl is-paused 2>/dev/null || printf 'false')
      waiting=$(dunstctl count waiting 2>/dev/null || printf '0')

      printf '{"paused":%s,"waiting":%s}\n' "$paused" "$waiting"
    }

    case "$1" in
      toggle)
        toggle
        ;;
      *)
        state
        ;;
    esac
  '';

  ewwScripts = pkgs.runCommand "eww-scripts" { } ''
    cp -r ${./config/scripts} $out
    chmod -R u+w $out
    install -m755 ${notificationScript} $out/notifications
  '';
in
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
    "eww/scripts".source = ewwScripts;
  };
}
