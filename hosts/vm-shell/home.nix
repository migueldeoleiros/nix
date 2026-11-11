{ pkgs, vars, ... }:

{
  imports = (
    import ../../modules/home-manager/shell ++
    import ../../modules/home-manager/gnupg ++
    import ../../modules/home-manager/agent-secrets ++
    import ../../modules/home-manager/tmux ++
    import ../../modules/home-manager/yazi ++
    import ../../modules/home-manager/neovim ++
    import ../../modules/home-manager/dev/rust ++
    import ../../modules/home-manager/dev/nodejs ++
    import ../../modules/home-manager/dev/java ++
    import ../../modules/home-manager/opencode ++
    import ../../modules/home-manager/pi
  );

  miguel.opencode = {
    profile = "inditex";
    enabledProfiles = [ "inditex" ];
  };

  miguel.agentSecrets.enable = true;

  miguel.pi = {
    defaultProfile = "inditex";
    enabledProfiles = [ "merlin" "personal" "inditex" ];
  };

  home = {
    username = vars.user;
    homeDirectory = "/home/${vars.user}";
    stateVersion = "26.05";
  };

  miguel.gnupg.graphical = false;

  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };
  # Headless sessions still need a running provider; unlocking stays explicit.
  systemd.user.services.gnome-keyring.Install.WantedBy = [ "default.target" ];

  # Required for standalone Home Manager on non-NixOS systems.
  targets.genericLinux.enable = true;
  nix.package = pkgs.nix;
  programs.home-manager.enable = true;
}
