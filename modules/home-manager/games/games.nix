{pkgs, config, lib, vars, osConfig ? {}, ...}:

{
  home = {
    packages = with pkgs; [
      osu-lazer-bin
      # lutris
      gamescope
      # modrinth-app
      jdk
    ] ++ lib.optionals (!(lib.attrByPath [ "programs" "steam" "enable" ] false osConfig)) [
      steam
    ];
  };
}
