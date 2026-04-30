{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/profiles/base-desktop.nix
  ] ++
    import ../../modules/nixos/syncthing ++
    import ../../modules/nixos/flatpak ++
    import ../../modules/nixos/gnupg ++
    import ../../modules/nixos/netbird;

  services.netbird.enable = true;

  system.stateVersion = "25.11";
}
