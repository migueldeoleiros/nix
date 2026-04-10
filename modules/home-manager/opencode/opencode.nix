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

      "opencode.agent.quick.md" = {
        text = ''
          ---
          name: quick
          description: Free model for simple tasks - use for quick edits and simple queries
          mode: primary
          model: opencode/big-pickle
          temperature: 0.3
          ---

          You are a quick task agent. Keep responses concise and focused.
        '';
        target = ".config/opencode/agent/quick.md";
        force = true;
      };
    };
  };
}