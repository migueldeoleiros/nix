{ host, lib, pkgs, ... }:

{
  services.batsignal = {
    enable = true;
    extraArgs = [
      "-n" host.batteryId
      # Fixed polling avoids long gaps when the battery drains quickly.
      "-m" "+30"
      "-w" "25"
      "-c" "10"
      "-d" "5"
      "-W" "Battery low — plug in your charger"
      "-C" "Battery critically low — plug in your charger now"
      # The danger threshold runs a command rather than sending a notification.
      # Notify only: never suspend or shut down automatically.
      "-D" (lib.escapeShellArgs [
        "${pkgs.libnotify}/bin/notify-send"
        "--app-name=batsignal"
        "--urgency=critical"
        "--expire-time=0"
        "Battery almost empty"
        "Battery at 5% or less. Plug in your charger immediately."
      ])
    ];
  };
}
