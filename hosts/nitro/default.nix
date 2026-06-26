{ inputs, lib, pkgs, system, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ../../modules/nixos/profiles/base-desktop.nix
  ] ++
      import ../../modules/nixos/btop ++
  #   import ../../modules/nixos/vm ++
      import ../../modules/nixos/syncthing ++
      import ../../modules/nixos/docker ++
      import ../../modules/nixos/flatpak ++
      import ../../modules/nixos/gnupg ++
      import ../../modules/nixos/kdeconnect ++
      import ../../modules/nixos/netbird;

  services.netbird.enable = true;

  system.stateVersion = "25.11";
}
