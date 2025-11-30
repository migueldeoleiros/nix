{ config, pkgs, vars, ... }:

{
  virtualisation = {
    virtualbox = {
      host = {
        enable = true;  
        enableExtensionPack = true;
      };
    };
  };

  users = {
    extraGroups.vboxusers.members = [ "virtualbox" ]; 
    users.${vars.user}.extraGroups = [ "virtualbox" ];
  };
}
