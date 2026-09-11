{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.gnupg ];
}
