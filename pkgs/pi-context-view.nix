{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "pi-context-view";
  version = "0.8.3";

  src = fetchurl {
    url = "https://registry.npmjs.org/pi-context-view/-/pi-context-view-${version}.tgz";
    hash = "sha512-gkeblBXXwz0uxhCSWa4RrMU64E3TYHr8vSyM10wcIkOAKaL8zoO6ob4bE9s+KjFfNVZ7WcPClSDnOOo2BjyhUw==";
  };

  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/node_modules/pi-context-view"
    tar -xzf "$src" --strip-components=1 -C "$out/lib/node_modules/pi-context-view"
    runHook postInstall
  '';

  meta = {
    description = "Pi extension for inspecting context usage and prompt contents";
    homepage = "https://github.com/dimk90/pi-context-view";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
