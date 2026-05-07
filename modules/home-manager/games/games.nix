{pkgs, config, lib, vars, ...}:

{
  home = {
    packages = with pkgs; [
      osu-lazer-bin
      (millennium-steam.override {
        extraPkgs = pkgs: with pkgs; [
          libXcursor
          libXi
          libXinerama
          libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
        ];
      })
      # lutris
      gamescope
      modrinth-app
      jdk
    ];
  };
}
