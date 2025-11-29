{ config, pkgs, lib, ... }:

{
  programs.tmux = {
    enable = true;

    # Use Alt+a as prefix
    prefix = "M-a";

    # Settings
    terminal = "xterm-256color";
    historyLimit = 50000;
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 0;
    clock24 = true;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      battery
    ];

    extraConfig = ''
      # Additional settings
      set -g display-time 4000
      set buffer-limit 10
      set -g focus-events on
      set -g status-keys vi
      set -g pane-base-index 1

      # Titles
      set -g set-titles on
      set -g set-titles-string ' #I-#W #T'

      # Window options
      set-window-option -g monitor-activity on
      set-window-option -g xterm-keys on
      set-window-option -g automatic-rename on

      # Statusbar
      set -g status-interval 5
      set -g status-justify left
      set -g status-left-length 96
      set -g status-right-length 64
      set -g status-right '#{battery_status_bg} Batt: #{battery_icon} #{battery_percentage} #{battery_remain} | %a %h-%d %H:%M '
      set-window-option -g window-status-format ' #I-#W '
      set-window-option -g window-status-current-format ' #I-#W '
      set -g status-bg black
      set -g status-fg white

      # Terminal overrides
      set -g terminal-overrides 'xterm*:smcup@:rmcup@'

      # Update environment
      set -g update-environment "DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY BSPWM_SOCKET PATH"

      # Copy mode with xclip
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

      ### Keybinds ###

      # Prefix keys
      bind-key M-a send-prefix
      bind-key -n C-a send-prefix

      # Reload config
      bind-key -n M-r run-shell 'tmux source-file ~/.config/tmux/tmux.conf; tmux display-message "Sourced tmux.conf!"'
      bind-key -T prefix r run-shell 'tmux source-file ~/.config/tmux/tmux.conf; tmux display-message "Sourced tmux.conf!"'

      # Command prompts
      bind-key -n M-"n" command-prompt -p "tmux:"
      bind-key -T prefix n command-prompt -p "tmux:"
      bind-key -n M-"m" command-prompt -p "man:" "split-window -h 'man %%'"
      bind-key -T prefix "m" command-prompt -p "man:" "split-window -h 'man %%'"

      # List keys
      bind-key -n M-/ list-keys

      # Copy mode
      bind-key -T prefix v copy-mode
      bind-key -T copy-mode-vi C-g send-keys -X cancel
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection
      bind-key -T copy-mode-vi r send-keys -X rectangle-toggle

      # Sessions
      bind-key -n M-e choose-session
      bind-key e choose-session
      bind-key -n M-t command-prompt -I \#S "rename-session '%%'"
      bind-key t command-prompt -I \#S "rename-session '%%'"

      # Windows
      bind-key -n M-w list-windows
      bind-key -T prefix w list-windows
      bind-key -n M-\` last-window
      bind-key -n M-c new-window
      bind-key -n M-x confirm-before kill-pane

      # Splits
      bind-key -n M-s split-window -v
      bind-key -T prefix s split-window -v
      bind-key -n M-v split-window -h

      # Window selection
      bind-key -n M-"'" command-prompt -p index "select-window -t ':%%'"
      bind-key -n C-1 select-window -t 1
      bind-key -T prefix 1 select-window -t 1
      bind-key -n C-2 select-window -t 2
      bind-key -T prefix 2 select-window -t 2
      bind-key -n C-3 select-window -t 3
      bind-key -T prefix 3 select-window -t 3
      bind-key -n C-4 select-window -t 4
      bind-key -T prefix 4 select-window -t 4
      bind-key -n C-5 select-window -t 5
      bind-key -T prefix 5 select-window -t 5
      bind-key -n C-6 select-window -t 6
      bind-key -T prefix 6 select-window -t 6
      bind-key -n C-7 select-window -t 7
      bind-key -T prefix 7 select-window -t 7
      bind-key -n C-8 select-window -t 8
      bind-key -T prefix 8 select-window -t 8
      bind-key -n C-9 select-window -t 9
      bind-key -T prefix 9 select-window -t 9
      bind-key -n C-0 select-window -t 10
      bind-key -T prefix 0 select-window -t 10
      bind-key -n M-"-" select-window -t 11
      bind-key -T prefix "-" select-window -t 1
      bind-key -n M-"=" select-window -t 12
      bind-key -T prefix "=" select-window -t 1

      # Pane navigation
      bind-key -n M-Tab last-pane
      bind-key -n M-h select-pane -L
      bind-key -n M-l select-pane -R
      bind-key -n M-j select-pane -D
      bind-key -n M-k select-pane -U

      # Pane resize
      bind-key -n C-'Left' resize-pane -L 5
      bind-key -r -T prefix 'Left' resize-pane -L 5
      bind-key -n C-'Right' resize-pane -R 5
      bind-key -r -T prefix 'Right' resize-pane -R 5
      bind-key -n C-'Down' resize-pane -D 5
      bind-key -r -T prefix 'Down' resize-pane -D 5
      bind-key -n C-'Up' resize-pane -U 5
      bind-key -r -T prefix 'Up' resize-pane -U 5

      # Pane swap
      bind-key -n M-"." swap-pane -D
      bind-key -n M-"," swap-pane -U
    '';
  };
}
