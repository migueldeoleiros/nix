{ config, pkgs, vars, ... }:

{
  services.syncthing = {
    enable = true;
    user = "${vars.user}";
    dataDir = "/home/${vars.user}/.local/share/syncthing";
    configDir = "/home/${vars.user}/.config/syncthing";

    # Open ports in firewall for syncthing
    openDefaultPorts = true;

    # Web UI settings
    guiAddress = "127.0.0.1:8384";
  };
}
