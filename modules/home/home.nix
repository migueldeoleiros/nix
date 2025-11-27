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
      evince

      telegram-desktop
      vesktop

      nautilus
      gvfs
      eog
      gnome-calculator
      gnome-font-viewer
      wdisplays
      pavucontrol

      pixelorama
      gimp
      inkscape

      anki
      warpinator
      qbittorrent
      
      (pkgs.callPackage ../../pkgs/st.nix {})
      (pkgs.callPackage ../../pkgs/pear-desktop.nix {})
    ];
  };
}
