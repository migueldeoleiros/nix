{ config, pkgs, vars, ... }:

{
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
    };
    settings = {
      close_on_focus_loss= false;
      consider_preedit= false;
      favicon_service= "twenty";
      font= {
        size= 10.5;
      };
      keybinding= "default";
      keybinds= {
      };
      pop_to_root_on_close= true;
      root_search= {
        search_files= false;
      };
      theme= {
        name= "vicinae-dark";
      };
      window= {
        csd= true;
        opacity= 0.98;
        rounding= 10;
      };
    };
  };
}
