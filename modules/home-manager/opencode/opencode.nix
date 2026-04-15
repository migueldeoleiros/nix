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

      "opencode.dcp.json" = {
        source = ./dcp.json;
        target = ".config/opencode/dcp.json";
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

      "opencode.agents" = {
        source = ./agents;
        target = ".config/opencode/agents";
        recursive = true;
        force = true;
      };

      "opencode.commands" = {
        source = ./commands;
        target = ".config/opencode/commands";
        recursive = true;
        force = true;
      };

      "opencode.skills" = {
        source = ./skills;
        target = ".config/opencode/skills";
        recursive = true;
        force = true;
      };

    };
  };
}
