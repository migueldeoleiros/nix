{ pkgs, ... }:

{
  # GLPI OAuth credentials live outside git and the Nix store. Create them with:
  # sudo install -d -m 0700 -o root -g root /etc/glpi-agent
  # sudoedit /etc/glpi-agent/glpi.keys
  # sudo chmod 0600 /etc/glpi-agent/glpi.keys
  #
  # Expected /etc/glpi-agent/glpi.keys contents:
  # oauth-client-id = <client-id>
  # oauth-client-secret = <client-secret>
  environment.systemPackages = [ pkgs.glpi-agent ];

  services.glpiAgent = {
    enable = true;
    settings = {
      server = [ "https://it.merlinsoftware.es/marketplace/glpiinventory/" ];
      include = "/etc/glpi-agent/glpi.keys";
    };
  };

  systemd.tmpfiles.rules = [
    "d /etc/glpi-agent 0700 root root - -"
  ];
}
