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
    sessionVariables = {
      EDITOR = "nvim";
    };

    packages = with pkgs; [
      # CLI extras
      neofetch
      gh
      btop
      ledger
      gnuplot
      imagemagickBig

      # Browsers & productivity
      firefox
      chromium
      thunderbird
      libreoffice
      emacs
      emacs-all-the-icons-fonts

      # Media
      mpv
      kdePackages.okular
      tauon
      jellyfin-desktop

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
      snapshot
      cameractrls-gtk4
      helvum
      drawing
      gparted
      picard

      # Creative
      pixelorama
      gimp
      inkscape

      # Other apps
      anki
      warpinator
      qbittorrent
      wine
      gemini-cli-bin

      # Writing/LaTeX
      texlive.combined.scheme-full
      pandoc

      # Custom packages
      (pkgs.callPackage ../../../pkgs/st.nix {})
      (pkgs.callPackage ../../../pkgs/pear-desktop.nix {})
    ];
  };
}
