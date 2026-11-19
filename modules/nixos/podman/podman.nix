{ vars, ... }:

{
  # Rootless Podman for the shared browser container; coexists with rootful Docker.
  virtualisation.podman.enable = true;
  users.users.${vars.user}.autoSubUidGidRange = true;
}
