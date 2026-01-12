{ config, pkgs, vars, ... }:

{
  programs = {
    zsh = {
      enable = true;
      autocd = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      initContent = ''

       export PATH="$HOME/programs/flutter/bin:$PATH"
       export PATH="$HOME/.local/bin:$PATH"
       export EDITOR="nvim"
       export VISUAL="nvim"

        #vi mode
        bindkey -v
        export KEYTIMEOUT=1
        bindkey "^?" backward-delete-char
        # Change cursor shape for different vi modes.
        function zle-keymap-select {
          if [[ ''${KEYMAP} == vicmd ]] ||
             [[ $1 = 'block' ]]; then
             echo -ne '\e[1 q'
          elif [[ ''${KEYMAP} == main ]] ||
               [[ ''${KEYMAP} == viins ]] ||
               [[ ''${KEYMAP} = ' ' ]] ||
               [[ $1 = 'beam' ]]; then
               echo -ne '\e[5 q'
          fi
        }
        zle -N zle-keyma p-select

        # Yazi directory navigation function
        function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        }
      '';
    };
    
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        # Get editor completions based on the config schema
        "$schema" = "https://starship.rs/config-schema.json";
        
        # Inserts a blank line between shell prompts
        add_newline = true;
        
        character = {
          success_symbol = "[❯](bold green)";
        };
      };
    };
    
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home = {
    packages = with pkgs; [
      eza
      trash-cli
    ];
  };
}
