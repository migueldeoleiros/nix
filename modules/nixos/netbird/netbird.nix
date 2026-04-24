# Extend nixpkgs' netbird module with user-level systemd service
{ config, pkgs, lib, ... }:

{
  # Add netbird package and user service
  environment.systemPackages = [ pkgs.netbird ];

  systemd.user.services.netbird = {
    description = "Netbird VPN";
    # Set to [] to keep NetBird installed but require manual `systemctl --user start netbird`.
    wantedBy = [ "default.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.netbird}/bin/netbird up";
      ExecStop = "${pkgs.netbird}/bin/netbird down";
      Restart = "on-failure";
    };
  };
}
