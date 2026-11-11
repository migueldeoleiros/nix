{ config, pkgs, lib, ... }:
let
  cfg = config.miguel.pi;
  profiles = import ./config/profiles.nix;
  aicontextProfiles = lib.filter (profile: profiles.${profile}.aicontext or false) cfg.enabledProfiles;
  pi = pkgs.pi-coding-agent;
  piPackageDir = "${pi}/lib/node_modules/pi-monorepo";
  profileDir = profile: "${config.xdg.configHome}/pi-${profile}";
  profileSessionDir = profile: "${config.xdg.dataHome}/pi/${profile}/sessions";
  render = source: replacements:
    builtins.replaceStrings (map (x: x.key) replacements) (map (x: x.value) replacements) source;
  childProfile = render (builtins.readFile ./scripts/child-profile.sh) [
    { key = "@PROFILE_ROOTS@"; value = lib.concatMapStringsSep "\n" (profile: ''
      if [ "$inherited_agent_dir" = ${lib.escapeShellArg (profileDir profile)} ]; then
        inherited_profile=${lib.escapeShellArg profile}
      fi
    '') [ "merlin" "personal" "inditex" ]; }
    { key = "@PROFILE_EXPORTS@"; value = lib.concatMapStringsSep "\n" (profile: ''
      ${profile}) export PI_CODING_AGENT_DIR=${lib.escapeShellArg (profileDir profile)}; export PI_CODING_AGENT_SESSION_DIR=${lib.escapeShellArg (profileSessionDir profile)} ;;
    '') [ "merlin" "personal" "inditex" ]; }
  ];
  piLaunch = render (builtins.readFile ./scripts/pi-launch.sh) [
    { key = "@PI_EXE@"; value = lib.escapeShellArg (lib.getExe pi); }
    { key = "@AICONTEXT_AGENT_DIRS@"; value = if aicontextProfiles == [ ] then "''" else lib.concatMapStringsSep "|" (profile: lib.escapeShellArg (profileDir profile)) aicontextProfiles; }
  ];
  launcher = profile: pkgs.writeShellApplication {
    name = "pi-${profile}";
    runtimeInputs = [ pkgs.coreutils pkgs.tmux ];
    text = render (builtins.readFile ./scripts/profile-launcher.sh) [
      { key = "@CHILD_PROFILE@"; value = childProfile; }
      { key = "@PROFILE@"; value = lib.escapeShellArg profile; }
      { key = "@PROFILE_DIR@"; value = lib.escapeShellArg (profileDir profile); }
      { key = "@SESSION_DIR@"; value = lib.escapeShellArg (profileSessionDir profile); }
      { key = "@PI_PACKAGE_DIR@"; value = lib.escapeShellArg piPackageDir; }
      { key = "@PI_LAUNCH@"; value = piLaunch; }
    ];
  };
  profileSelector = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = [ pkgs.coreutils pkgs.git pkgs.tmux ];
    text = render (builtins.readFile ./scripts/profile-selector.sh) [
      { key = "@CHILD_PROFILE@"; value = childProfile; }
      { key = "@DEFAULT_PROFILE@"; value = lib.escapeShellArg cfg.defaultProfile; }
      { key = "@ENABLED_PROFILES@"; value = lib.escapeShellArg (lib.concatStringsSep " " cfg.enabledProfiles); }
      { key = "@PROFILE_CHOICES@"; value = lib.concatMapStringsSep "\n" (profile: ''
        ${profile})
          export PI_CODING_AGENT_DIR=${lib.escapeShellArg (profileDir profile)}
          export PI_CODING_AGENT_SESSION_DIR=${lib.escapeShellArg (profileSessionDir profile)}
          export PI_PACKAGE_DIR=${lib.escapeShellArg piPackageDir} ;;
      '') [ "merlin" "personal" "inditex" ]; }
      { key = "@PI_LAUNCH@"; value = piLaunch; }
    ];
  };
in {
  home.packages = [ profileSelector ] ++ map launcher cfg.enabledProfiles;
}
