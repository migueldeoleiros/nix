{ config, pkgs, lib, ... }:

let
  javaVersions = {
    jdk8  = pkgs.jdk8;
    jdk17 = pkgs.jdk17;
    jdk21 = pkgs.jdk21;
  };

  defaultJava = javaVersions.jdk21;
in
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home = {
    packages = with pkgs; [
      maven
    ];

    file = lib.mapAttrs' (name: package:
      lib.nameValuePair ".local/share/jdks/${name}" {
        source = package;
      }) javaVersions;

    sessionVariables = {
      JAVA_HOME = "${defaultJava}";
    };

    sessionPath = [
      "${defaultJava}/bin"
    ];
  };
}
