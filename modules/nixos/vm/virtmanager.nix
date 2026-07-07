{ pkgs, vars, ... }:

{
  # Enable dconf (System Management Tool)
  programs.dconf.enable = true;

  # Add user to libvirtd group
  users.users.${vars.user}.extraGroups = [ "libvirtd" "kvm" ];

  programs.virt-manager.enable = true;

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    dnsmasq
    spice spice-gtk
    spice-protocol
    virtio-win
    win-spice
    adwaita-icon-theme
    virtiofsd
    # xpra # Enable if single-app VM windows are needed later.
  ];

  # Manage the virtualisation services
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;
}
