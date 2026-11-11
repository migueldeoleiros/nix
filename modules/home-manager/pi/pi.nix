{ config, lib, ... }:
{
  imports = [ ./launchers.nix ./mcp.nix ./assets.nix ];

  options.miguel.pi.enabledProfiles = lib.mkOption {
    type = lib.types.listOf (lib.types.enum [ "merlin" "personal" "inditex" ]);
    default = [ "personal" ];
    description = "Pi profiles to materialize as isolated launchers and agent directories.";
  };

  options.miguel.pi.defaultProfile = lib.mkOption {
    type = lib.types.enum [ "merlin" "personal" "inditex" ];
    default = "personal";
    description = "Profile used by pi when no .pi-profile marker applies.";
  };

  config.assertions = [
    {
      assertion = !(lib.elem "merlin" config.miguel.pi.enabledProfiles)
        || (config.miguel.agentSecrets.enable or false);
      message = "Pi Merlin requires miguel.agentSecrets.enable.";
    }
    {
      assertion = lib.elem config.miguel.pi.defaultProfile config.miguel.pi.enabledProfiles;
      message = "miguel.pi.enabledProfiles must contain miguel.pi.defaultProfile.";
    }
  ];
}
