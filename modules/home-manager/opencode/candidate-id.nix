{ pkgs }:

pkgs.writeShellApplication {
  name = "opencode-candidate-id";
  runtimeInputs = [ pkgs.git pkgs.python3 ];
  text = ''
    exec ${pkgs.python3}/bin/python ${./scripts/candidate-id.py} "$@"
  '';
}
