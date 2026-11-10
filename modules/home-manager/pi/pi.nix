{ config, lib, ... }:
{
  imports = [ ./launchers.nix ./mcp.nix ./assets.nix ];

  options.miguel.pi.enabledProfiles = lib.mkOption {
    type = lib.types.listOf (lib.types.enum [ "merlin" "personal" "inditex" ]);
    default = [ "personal" ];
    description = "Pi profiles to materialize as isolated launchers and agent directories.";
  };

  config.assertions = [
    {
      assertion = lib.elem "personal" config.miguel.pi.enabledProfiles;
      message = "miguel.pi.enabledProfiles must contain personal, the safe default profile for unmarked projects.";
    }
  ];
}
