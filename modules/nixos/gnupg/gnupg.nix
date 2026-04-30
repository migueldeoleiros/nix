{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.gnupg ];

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
}
