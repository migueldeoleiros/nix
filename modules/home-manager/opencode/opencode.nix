{ config, pkgs, lib, ... }:

{
  home = {
    packages = with pkgs; [
      opencode
      nodejs
    ];

    file = {
      "opencode.json" = {
        source = ./opencode.json;
        target = ".config/opencode/opencode.json";
        force = true;
      };

      "oh-my-openagent.json" = {
        source = ./oh-my-openagent.json;
        target = ".config/opencode/oh-my-openagent.json";
        force = true;
      };

      "opencode.gitignore" = {
        text = ''
          node_modules
          package.json
          package-lock.json
          bun.lock
          .gitignore
        '';
        target = ".config/opencode/.gitignore";
        force = true;
      };
    };
  };
}