{ config, pkgs, lib, ... }:

{
  home.packages = [ pkgs.neovim ];

  # Source individual files instead of the whole directory
  # so lazy.nvim can write lazy-lock.json to ~/.config/nvim/
  xdg.configFile."nvim/init.lua".source = ./nvim-config/init.lua;
  xdg.configFile."nvim/lua/plugins".source = ./nvim-config/lua/plugins;
}
