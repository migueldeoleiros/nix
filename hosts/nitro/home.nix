{ vars, ... }:

{
  imports = (
  #   import ../../modules/home-manager/qutebrowser ++
      import ../../modules/home-manager/shell ++
      import ../../modules/home-manager/rofi ++
      import ../../modules/home-manager/gtk ++
      import ../../modules/home-manager/bitwarden ++
      import ../../modules/home-manager/yazi ++
      import ../../modules/home-manager/fcitx5 ++
      import ../../modules/home-manager/games ++
      import ../../modules/home-manager/hyprland ++
      import ../../modules/home-manager/kitty ++
      import ../../modules/home-manager/tmux ++
      import ../../modules/home-manager/neovim ++
      import ../../modules/home-manager/packages ++
      import ../../modules/home-manager/vicinae ++
      import ../../modules/home-manager/rust
  );

  home = {
    username = vars.user;
    homeDirectory = "/home/${vars.user}";
    stateVersion = "23.05";
  };

  programs.home-manager.enable = true;
}
