{pkgs, config, lib, vars, ...}:

{
  home = {
    packages = with pkgs; [
      osu-lazer-bin
      steam
      # lutris
      gamescope
      modrinth-app
      jdk
    ];
  };
}
