{ config, pkgs, lib, ... }:

{
  # Power saver mode on boot 
  specialisation = {
    power-saver.configuration = {
      system.nixos.tags = [ "power-saver" ];
      hardware.nvidia = {
        prime.offload.enable = lib.mkForce true;
        prime.offload.enableOffloadCmd = lib.mkForce true;
        prime.sync.enable = lib.mkForce false;
      };
    };
  };

  # Better scheduling for CPU cycles
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  # Enable TLP
  services.tlp = {
    enable = true;
    settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      USB_AUTOSUSPEND = 0;
      USB_DENYLIST = "046d:c53f"; # disable suspend on mouse
    };
  };

  # Disable GNOMEs power management
  services.power-profiles-daemon.enable = false;

  # Enable thermald if using Intel CPU
  # services.thermald.enable = true;
}
