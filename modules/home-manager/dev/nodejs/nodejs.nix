{ config, pkgs, lib, ... }:

{
  home = {
    packages = with pkgs; [
      astro-language-server
      nodejs
      pnpm
    ];
  };
}
