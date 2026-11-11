{ lib, stdenvNoCC, python3, libsecret, zenity, makeWrapper }:

let
  python = python3.withPackages (packages: [ packages.pygobject3 ]);
in
stdenvNoCC.mkDerivation {
  pname = "agent-secrets";
  version = "1.0.0";
  src = ./scripts;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ libsecret ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec" "$out/bin"
    install -m 0444 ./*.py "$out/libexec/"
    makeWrapper ${python}/bin/python "$out/bin/agent-secrets" \
      --add-flags "$out/libexec/agent-secrets.py" \
      --set GI_TYPELIB_PATH "${libsecret}/lib/girepository-1.0" \
      --set LD_LIBRARY_PATH "${libsecret}/lib" \
      --set ZENITY "${zenity}/bin/zenity"
    runHook postInstall
  '';

  meta = {
    description = "Bounded Secret Service enrollment and private credential delivery";
    platforms = lib.platforms.linux;
  };
}
