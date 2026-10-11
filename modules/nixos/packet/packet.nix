{ pkgs, vars, ... }:

{
  # Packet (Quick Share client) needs an inbound TCP port for Android devices to connect back to.
  # Pin it to 9300 (Static Network Port) and open it in the
  # NixOS firewall. UDP 5353 is already opened by services.avahi.openFirewall.
  networking.firewall.allowedTCPPorts = [ 9300 ];

  home-manager.users.${vars.user} = {
    home.packages = [ pkgs.packet ];

    dconf.settings."io/github/nozwock/Packet" = {
      enable-static-port = true;
      static-port-number = 9300;
    };
  };
}
