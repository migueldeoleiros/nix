{pkgs, config, lib, vars, ...}:

{
  home = {
    packages = with pkgs; [
      dconf
      dconf-editor
      kdePackages.breeze
      kdePackages.breeze-icons
      kdePackages.qtstyleplugin-kvantum
      libsForQt5.qtstyleplugin-kvantum
      qadwaitadecorations-qt6
    ];

    pointerCursor = {
      enable = true;
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
        gtk-theme = "Adwaita-dark";
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
      };
      bookmarks = [
        "file:///home/${vars.user}/downloads"
        "file:///home/${vars.user}/documents"
        "file:///home/${vars.user}/pictures"
        "file:///home/${vars.user}/pictures/Screenshots"
        "sftp://192.168.1.135/volume1/home/admin asustor"
      ];
    };
    gtk4 = {
      theme = config.gtk.theme;
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };

  xdg.configFile = {
    "Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=KvSimplicityDark
    '';

    # KDE apps read this outside Plasma too. Use the full Breeze Dark color
    # scheme; a minimal kdeglobals can make apps fall back to a light palette.
    "kdeglobals".text = builtins.readFile "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors" + ''

      [Icons]
      Theme=breeze-dark

      [KDE]
      widgetStyle=kvantum
    '';
  };

  # Use qtct + Kvantum so Qt5/Qt6 apps are themed from files, not UI tools.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";

    qt5ctSettings.Appearance = {
      style = "kvantum";
      icon_theme = "breeze-dark";
      standard_dialogs = "xdgdesktopportal";
    };

    qt6ctSettings.Appearance = {
      style = "kvantum";
      icon_theme = "breeze-dark";
      standard_dialogs = "xdgdesktopportal";
    };
  };
}
