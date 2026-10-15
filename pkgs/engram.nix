{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "engram";
  version = "3.4.0";

  src = fetchurl {
    url = "https://github.com/Gentleman-Programming/engram/releases/download/v${version}/engram_${version}_linux_amd64.tar.gz";
    sha256 = "715fda625556e46d65ddb4526bb7f88a3fee5339ca3c44ce44cc652f17fa57f1";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 engram $out/bin/engram
    runHook postInstall
  '';

  meta = {
    description = "Persistent memory system for AI coding agents";
    homepage = "https://github.com/Gentleman-Programming/engram";
    license = lib.licenses.mit;
    mainProgram = "engram";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
