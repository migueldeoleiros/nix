{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "pi-visor";
  version = "0.2.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/pi-visor/-/pi-visor-${version}.tgz";
    hash = "sha512-V659Dj0c2G9LPF4vkjt0QDKNj2ap/Wqsng5pGubM3Vppzad3H3HrMQVqtUBJrTzEqvXo+TSvmMq9U4xp6Z8mpw==";
  };

  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/node_modules/pi-visor"
    tar -xzf "$src" --strip-components=1 -C "$out/lib/node_modules/pi-visor"
    runHook postInstall
  '';

  meta = {
    description = "Pi TUI heads-up display with turn bar and compact tool blocks";
    homepage = "https://github.com/laveesingh/awesome-pi-extensions/tree/main/packages/visor";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
