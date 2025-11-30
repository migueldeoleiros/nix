{ vars, pkgs, ... }:

{
  imports = (
      import ../../modules/home-manager/shell ++
      import ../../modules/home-manager/rofi ++
      import ../../modules/home-manager/gtk ++
      import ../../modules/home-manager/yazi ++
      import ../../modules/home-manager/fcitx5 ++
#      import ../../modules/home-manager/hyprland ++
      import ../../modules/home-manager/kitty ++
      import ../../modules/home-manager/tmux ++
      import ../../modules/home-manager/neovim ++
      import ../../modules/home-manager/rust
  );

  home = {
    username = vars.user;
    homeDirectory = "/home/${vars.user}";
    stateVersion = "23.05";
  };

  # Required for standalone home-manager on non-NixOS
  targets.genericLinux.enable = true;

  programs.home-manager.enable = true;

  # XDG directories
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "$HOME";
    download = "$HOME/downloads";
    templates = "$HOME";
    publicShare = "$HOME";
    documents = "$HOME/documents";
    music = "$HOME/music";
    pictures = "$HOME/pictures";
    videos = "$HOME";
  };
}
