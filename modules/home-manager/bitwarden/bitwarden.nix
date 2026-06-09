{config, pkgs, inputs, vars, ...}:

{
  home.packages = with pkgs; [
    # the desktop package is using EOL electron
    # bitwarden-desktop
    bitwarden-cli
    bitwarden-menu
  ];
}
