{config, pkgs, inputs, vars, ...}:

{
  home.packages = with pkgs; [
    bitwarden-desktop
    bitwarden-cli
    bitwarden-menu
  ];
}
