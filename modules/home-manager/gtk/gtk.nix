{pkgs, config, lib, vars, ...}:

{
  home = {
    packages = with pkgs; [
      dconf
      dconf-editor
      adwaita-qt
      qadwaitadecorations-qt6
    ];

    # Force dark theme via environment variables
    sessionVariables = {
      # ADW_DISABLE_PORTAL = "1";
      QT_STYLE_OVERRIDE = "adwaita-dark";
    };

    pointerCursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };
  
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-im-module = "fcitx";
      };
      bookmarks = [
        "file:///home/miguel/downloads"
        "file:///home/miguel/documents"
        "file:///home/miguel/pictures"
        "file:///home/miguel/pictures/Screenshots"
        "sftp://192.168.1.135/volume1/home/admin asustor"
      ];
    };
    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-im-module = "fcitx";
      };
    };
  };

  # Use adwaita dark on Qt apps
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };
}
