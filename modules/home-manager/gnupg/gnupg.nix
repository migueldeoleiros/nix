{ config, pkgs, lib, ... }:

let
  cfg = config.miguel.gnupg;

  pinentryAuto = pkgs.writeShellScriptBin "pinentry-auto" ''
    if [ -n "''${DISPLAY:-}" ] || [ -n "''${WAYLAND_DISPLAY:-}" ]; then
      exec ${lib.getExe' pkgs.pinentry-gnome3 "pinentry-gnome3"} "$@"
    fi
    exec ${lib.getExe' pkgs.pinentry-curses "pinentry-curses"} "$@"
  '';

  pinentryPackage = if cfg.graphical then pinentryAuto else pkgs.pinentry-curses;
  pinentryProgram = if cfg.graphical then "pinentry-auto" else "pinentry-curses";
in
{
  options.miguel.gnupg = {
    enable = lib.mkEnableOption "Miguel's GnuPG setup" // {
      default = true;
    };

    graphical = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether a graphical session may exist on this host. When false only the
        curses pinentry is installed.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.gpg.enable = true;

    home.packages = lib.optionals cfg.graphical [ pkgs.gcr_3 ];

    services.gpg-agent = {
      enable = true;

      pinentry.package = pinentryPackage;
      pinentry.program = pinentryProgram;

      enableZshIntegration = true;

      defaultCacheTtl = 7200;
      maxCacheTtl = 28800;

      extraConfig = ''
        allow-emacs-pinentry
        allow-loopback-pinentry
      '';
    };
  };
}
