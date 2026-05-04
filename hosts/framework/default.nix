{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./wifi-workaround.nix
    ../../modules/nixos/profiles/base-desktop.nix
  ] ++
    import ../../modules/nixos/syncthing ++
    import ../../modules/nixos/docker ++
    import ../../modules/nixos/mysql ++
    import ../../modules/nixos/flatpak ++
    import ../../modules/nixos/gnupg ++
    import ../../modules/nixos/netbird;

  services.netbird.enable = true;
  services.hardware.bolt.enable = true;

  system.stateVersion = "25.11";
}
