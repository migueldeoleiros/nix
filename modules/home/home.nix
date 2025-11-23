{ config, pkgs, lib, vars, ... }:

{
  home = {
    username = "${vars.user}";
    homeDirectory = "/home/${vars.user}";

    stateVersion = "23.05";

    sessionVariables = {
      EDITOR = "nvim";
    };
    
    packages = with pkgs; [
      kitty
      neovim
      tldr
      tmux
      gh
      firefox
      thunderbird
      libreoffice
      emacs
      mpv
      telegram-desktop
      evince
      vesktop
      wdisplays
      pavucontrol
      gnome-font-viewer
      nautilus
      gvfs
      eog
      gnome-calculator
      qbittorrent
      pixelorama
      gimp
      inkscape
      anki
      warpinator
      (pkgs.callPackage ../../pkgs/st.nix {})
    ];
  };
}
