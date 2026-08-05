{ pkgs, vars, ... }:

{
  imports = (
    import ../../modules/home-manager/shell ++
    import ../../modules/home-manager/tmux ++
    import ../../modules/home-manager/yazi ++
    import ../../modules/home-manager/neovim ++
    import ../../modules/home-manager/dev/rust ++
    import ../../modules/home-manager/dev/nodejs ++
    import ../../modules/home-manager/dev/java ++
    import ../../modules/home-manager/opencode
  );

  miguel.opencode.profile = "inditex";

  home = {
    username = vars.user;
    homeDirectory = "/home/${vars.user}";
    stateVersion = "26.05";
  };

  # Required for standalone Home Manager on non-NixOS systems.
  targets.genericLinux.enable = true;
  nix.package = pkgs.nix;
  programs.home-manager.enable = true;
}
