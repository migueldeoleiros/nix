{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./glpi.nix
    ./wifi-workaround.nix
    ../../modules/nixos/profiles/base-desktop.nix
  ] ++
    import ../../modules/nixos/btop ++
    import ../../modules/nixos/syncthing ++
    import ../../modules/nixos/docker ++
    import ../../modules/nixos/vm ++
    import ../../modules/nixos/mysql ++
    import ../../modules/nixos/flatpak ++
    import ../../modules/nixos/gnupg ++
    import ../../modules/nixos/packet ++
    import ../../modules/nixos/orca ++
    import ../../modules/nixos/netbird;

  # TTY login unlocks the login keyring; Hyprland inherits the user session.
  services.gnome.gnome-keyring.enable = true;

  services.netbird.enable = true;
  services.hardware.bolt.enable = true;

  system.stateVersion = "25.11";
}
