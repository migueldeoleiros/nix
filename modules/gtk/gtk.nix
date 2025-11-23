{pkgs, config, lib, vars, ...}:

{
  home = {
    packages = with pkgs; [
      dconf
      dconf-editor
    ];
    
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
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
      bookmarks = [
        "file:///home/miguel/universidad"
        "file:///home/miguel/merlin"
        "sftp://192.168.1.135/volume1/home/admin asustor"
      ];
    };
    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };
  
  # use gtk theme on qt apps
  qt = {
    enable = true;
    platformTheme = "gtk";
  };
}
