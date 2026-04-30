{ config, pkgs, lib, vars, ... }:

{
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
    desktop = "$HOME";
    download = "$HOME/downloads";
    templates = "$HOME";
    publicShare = "$HOME";
    documents = "$HOME/documents";
    music = "$HOME/music";
    pictures = "$HOME/pictures";
    projects = "$HOME/projects";
    videos = "$HOME";
  };

  home = {
    sessionVariables = {
      EDITOR = "nvim";
    };

    packages = with pkgs; [
      # CLI extras
      fastfetch
      gh
      btop
      ledger
      (gnuplot.override {withQt = true;})
      imagemagickBig

      # Browsers & productivity
      firefox
      chromium
      thunderbird
      libreoffice
      dbeaver-bin

      # Emacs packages
      (emacs.pkgs.withPackages (epkgs: [ epkgs.jinx ]))
      emacs-all-the-icons-fonts
      enchant
      hunspell
      hunspellDicts.en_US
      hunspellDicts.es_ES
      hunspellDicts.pt_PT
      mupdf
      direnv

      # Media
      mpv
      wf-recorder
      slurp
      wl-clipboard
      kdePackages.okular
      tauon
      jellyfin-desktop
      grayjay

      # Communication
      telegram-desktop
      vesktop
      beeper

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
      crosspipe
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

      # Writing/LaTeX
      texlive.combined.scheme-full
      pandoc

      # Custom packages
      (pkgs.callPackage ../../../pkgs/st.nix {})
      (pkgs.callPackage ../../../pkgs/pear-desktop.nix {})
    ];
  };
}
