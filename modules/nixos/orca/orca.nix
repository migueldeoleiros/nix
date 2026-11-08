{ ... }:

{
  # Allow mobile clients to connect to Orca's WebSocket server.
  networking.firewall.allowedTCPPorts = [ 6768 ];
}
