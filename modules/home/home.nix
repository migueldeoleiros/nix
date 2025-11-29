{ config, pkgs, lib, vars, ... }:

{
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "$HOME";
    download = "$HOME/downloads";
    templates = "$HOME";
    publicShare = "$HOME";
    documents = "$HOME/documents";
    music = "$HOME/music";
    pictures = "$HOME/pictures";
    videos = "$HOME";
  };

  home = {
    username = "${vars.user}";
    homeDirectory = "/home/${vars.user}";

    stateVersion = "23.05";

    sessionVariables = {
      EDITOR = "nvim";
    };
    
    packages = with pkgs; [
      # CLI extras
      neofetch

      # Browsers & productivity
      firefox
      thunderbird
      libreoffice
      emacs
      emacs-all-the-icons-fonts

      # Media
      mpv
      evince

      # Communication
      telegram-desktop
      vesktop

      # Desktop utilities
      nautilus
      gvfs
      eog
      gnome-calculator
      gnome-font-viewer
      wdisplays
      pavucontrol

      # Creative
      pixelorama
      gimp
      inkscape

      # Other apps
      anki
      warpinator
      qbittorrent
      wine

      # Writing/LaTeX
      texlive.combined.scheme-full
      pandoc

      # Custom packages
      (pkgs.callPackage ../../pkgs/st.nix {})
      (pkgs.callPackage ../../pkgs/pear-desktop.nix {})
    ];
  };
}
