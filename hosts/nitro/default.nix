{ inputs, lib, pkgs, system, ... }:

let
  nitroKernelPkgs = import inputs.nixpkgs-nitro-kernel {
    inherit system;
    config.allowUnfree = true;
  };
in

{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ../../modules/nixos/profiles/base-desktop.nix
  ] ++
  #   import ../../modules/nixos/vm ++
      import ../../modules/nixos/syncthing ++
      import ../../modules/nixos/docker ++
      import ../../modules/nixos/flatpak ++
      import ../../modules/nixos/gnupg ++
      import ../../modules/nixos/netbird;

  # Keep MT7921 Bluetooth on the last known-good kernel/firmware stack.
  boot.kernelPackages = nitroKernelPkgs.linuxPackages;
  nixpkgs.overlays = [
    (_final: _prev: {
      linux-firmware = nitroKernelPkgs.linux-firmware;
    })
  ];

  services.netbird.enable = true;

  system.stateVersion = "25.11";
}
