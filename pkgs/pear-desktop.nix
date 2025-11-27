{ stdenvNoCC
, lib
, fetchurl
, gtk3
, libsecret
, nss
, mesa
, alsa-lib
, dpkg
, autoPatchelfHook
, makeWrapper
}:

let
  pname = "pear-desktop-bin";
  version = "3.11.0";
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/pear-devs/pear-desktop/releases/download/v${version}/youtube-music_${version}_amd64.deb";
    sha256 = "db20c40bdcc558aaa85d6d5c20a3ec1e32795fcd6ffaa7e4f99757004736face";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    gtk3
    libsecret
    nss
    mesa
    alsa-lib
  ];

  unpackPhase = ''
    dpkg -x $src .
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share

    # Install opt directory
    cp -r opt $out/

    # Move usr/share contents to $out/share
    cp -r usr/share/* $out/share/

    # Fix desktop file Exec path
    sed -i "s|Exec=.*|Exec=$out/bin/youtube-music %U|" $out/share/applications/youtube-music.desktop

    # Symlink the binary
    ln -s "$out/opt/YouTube Music/youtube-music" $out/bin/youtube-music
  '';

  meta = {
    description = "Pear Desktop (YouTube Music client) binary distribution";
    homepage = "https://github.com/pear-devs/pear-desktop";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
