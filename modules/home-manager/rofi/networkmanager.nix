{config, pkgs, inputs, vars, ...}:

{
  home = {
    packages = with pkgs; [
      networkmanager_dmenu
      networkmanagerapplet
    ];

    file = {
      ".config/networkmanager-dmenu/config.ini".text = ''
        [dmenu]
          dmenu_command = rofi -dmenu -i
      '';
    };
  };
}
