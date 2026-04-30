{ config, pkgs, lib, ... }:

let
  javaVersions = {
    jdk17 = pkgs.jdk17;
    jdk21 = pkgs.jdk21;
  };

  defaultJava = javaVersions.jdk21;
in
{
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
