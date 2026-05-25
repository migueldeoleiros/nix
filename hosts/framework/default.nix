{ inputs, system, ... }:

let
  frameworkKernelPkgs = import inputs.nixpkgs-nitro-kernel {
    inherit system;
    config.allowUnfree = true;
  };
in

{
  imports = [
    ./hardware-configuration.nix
    ./glpi.nix
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

  # Keep MT7925 Bluetooth on the last known-good kernel/firmware stack.
  boot.kernelPackages = frameworkKernelPkgs.linuxPackages;
  nixpkgs.overlays = [
    (_final: _prev: {
      linux-firmware = frameworkKernelPkgs.linux-firmware;
    })
  ];

  system.stateVersion = "25.11";
}
