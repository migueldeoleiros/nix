{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "pi-interactive-subagents";
  version = "3.7.2";

  src = fetchFromGitHub {
    owner = "amosblomqvist";
    repo = "pi-interactive-subagents";
    rev = "c3e8b53c0754ae5ccc19fdab5a7481ec039bc2f7";
    hash = "sha256-CuHDL6JV1VZoYIe+P/hk9qGMK71GGF7QRHEohsPKA2s=";
  };

  npmDepsHash = "sha256-MOaEVe8aXnwbUWEvPfF4NcD+6X+TZrfLhp4lPBqoYT8=";
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/node_modules/pi-interactive-subagents"
    # All external imports in this pin are Pi-provided peers (including legacy
    # @mariozechner/* and @sinclair/typebox aliases). Do not ship their dev copies.
    # Keep the full extension tree: children load subagent-done.ts, safe-bash.ts,
    # and the Claude plugin/hooks by relative path. Status needs the config example.
    cp -R package.json pi-extension agents config.json.example LICENSE README.md \
      "$out/lib/node_modules/pi-interactive-subagents/"
    runHook postInstall
  '';

  meta = {
    description = "Tmux-backed interactive Pi subagents with child-to-parent questions";
    homepage = "https://github.com/amosblomqvist/pi-interactive-subagents";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
