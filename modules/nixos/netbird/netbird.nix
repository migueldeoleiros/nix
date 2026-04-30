{ pkgs, ... }:

{
  services.netbird = {
    enable = true;
    package = pkgs.netbird;
  };
}
