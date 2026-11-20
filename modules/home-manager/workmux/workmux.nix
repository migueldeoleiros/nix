{ config, inputs, lib, pkgs, ... }:

# Worktree + tmux session manager: spawn, message (`workmux send`), and status for agents.
# Named agents map to the profile launchers so panes start with the right harness and config.
let
  ocProfiles = config.miguel.opencode.enabledProfiles;
  piProfiles = config.miguel.pi.enabledProfiles;
  # Launchers drop the profile suffix when only one profile is enabled (see opencode.nix, pi/launchers.nix).
  command = harness: profiles: p: if builtins.length profiles == 1 then harness else "${harness}-${p}";
  agents =
    lib.genAttrs (map (p: "opencode-${p}") ocProfiles) (name: { type = "opencode"; command = command "opencode" ocProfiles (lib.removePrefix "opencode-" name); })
    // lib.genAttrs (map (p: "pi-${p}") piProfiles) (name: { type = "pi"; command = command "pi" piProfiles (lib.removePrefix "pi-" name); });
in
{
  # Without a forced backend, workmux picks kitty when run from a kitty window outside tmux.
  # A wrapper applies from any launcher, with no re-login needed.
  home.packages = [
    (pkgs.symlinkJoin {
      name = "workmux-tmux";
      paths = [ inputs.workmux.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      # Pin workmux's state to the real XDG dir: the OpenCode launchers export a per-profile
      # XDG_STATE_HOME, which would otherwise hide hook-registered agents from the dashboard.
      postBuild = "wrapProgram $out/bin/workmux --set-default WORKMUX_BACKEND tmux --set XDG_STATE_HOME ${config.xdg.stateHome}";
    })
  ];

  xdg.configFile."workmux/config.yaml".text = builtins.toJSON {
    nerdfont = true; # the config is read-only, so workmux can't save its first-run prompt
    dashboard.close_on_jump = false;
    agent = "opencode-${config.miguel.opencode.profile}";
    inherit agents;
  };
}
