{ vars, pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  home-manager.users.${vars.user}.imports =
    import ../../home-manager/games;
}
