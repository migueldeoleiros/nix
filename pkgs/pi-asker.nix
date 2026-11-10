{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "pi-asker";
  version = "1.1.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/pi-asker/-/pi-asker-${version}.tgz";
    sha256 = "1yjgrbks1qx17ga91cbsd4zfm2gha04xp1l4a40b81bz0q1z82ip";
  };

  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/node_modules/pi-asker"
    tar -xzf "$src" --strip-components=1 -C "$out/lib/node_modules/pi-asker"
    runHook postInstall
  '';

  meta = {
    description = "Structured question tool for the Pi coding agent";
    homepage = "https://github.com/msvart/pi-asker";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
