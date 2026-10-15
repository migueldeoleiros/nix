{ lib, appimageTools, fetchurl, python3, stdenv }:

let
  pname = "stablyai-orca";
  version = "1.4.224";
  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-sf6RAtmH012X622cJ0qT2elRqtvoZPwiUaMVAj9gx0Y=";
  };
  python = python3.withPackages (packages: [ packages.pygobject3 ]);

  # Orca's own CliInstaller symlinks ~/.local/bin/orca-ide to
  # resources/bin/orca-ide inside the AppImage extraction. The bundled script
  # then runs the raw Electron binary next to the extraction root, which has
  # RPATH=$ORIGIN and relies on a host FHS at /lib for glib/gtk/etc. That fails
  # on non-NixOS or in sandboxed environments. Patch the symlink target to
  # delegate to the FHS-wrapped launcher installed by this package.
  appimageContents = appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      target=$out/resources/bin/orca-ide
      rm -f "$target"
      cat > "$target" <<'EOF'
      #!${stdenv.shell}
      set -euo pipefail

      # Resolve any ~/.local/bin/orca-ide symlink so resources paths point at
      # the real extraction directory.
      SOURCE="''${BASH_SOURCE[0]}"
      while [ -h "$SOURCE" ]; do
        DIR="$(cd "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
      done
      SCRIPT_DIR="$(cd "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
      RESOURCES_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

      CLI="$RESOURCES_DIR/app.asar.unpacked/out/cli/index.js"

      export ORCA_NODE_OPTIONS="''${NODE_OPTIONS-}"
      export ORCA_NODE_REPL_EXTERNAL_MODULE="''${NODE_REPL_EXTERNAL_MODULE-}"
      unset NODE_OPTIONS
      unset NODE_REPL_EXTERNAL_MODULE

      # The raw Electron binary lacks standard Nix library paths. Use the
      # FHS-wrapped launcher that appimageTools provides; it is installed
      # alongside this package and is expected to be on PATH.
      if ! command -v orca-ide-gui >/dev/null 2>&1; then
        echo "orca-ide-gui not found in PATH; ensure stablyai-orca is installed" >&2
        exit 1
      fi
      ELECTRON_RUN_AS_NODE=1 exec orca-ide-gui "$CLI" "$@"
      EOF
      chmod 755 "$target"
    '';
  };

  fhsLauncher = appimageTools.wrapAppImage {
    inherit pname version;
    contents = appimageContents;
    extraPkgs = pkgs: [
      pkgs.at-spi2-core
      pkgs.xclip
      pkgs.xdotool
      pkgs.xvfb
      python
    ];
  };
in
stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/applications
    ln -s ${fhsLauncher}/bin/${pname} $out/bin/orca-ide-gui

    cat > $out/bin/orca-ide <<'EOF'
    #!${stdenv.shell}
    set -euo pipefail

    script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
    export ORCA_NODE_OPTIONS="''${NODE_OPTIONS-}"
    export ORCA_NODE_REPL_EXTERNAL_MODULE="''${NODE_REPL_EXTERNAL_MODULE-}"
    unset NODE_OPTIONS
    unset NODE_REPL_EXTERNAL_MODULE

    ELECTRON_RUN_AS_NODE=1 exec "$script_dir/orca-ide-gui" \
      "${appimageContents}/resources/app.asar.unpacked/out/cli/index.js" "$@"
    EOF
    chmod 755 $out/bin/orca-ide

    install -Dm444 ${appimageContents}/orca-ide.desktop \
      $out/share/applications/orca-ide.desktop
    substituteInPlace $out/share/applications/orca-ide.desktop \
      --replace-fail "Exec=AppRun %U" "Exec=orca-ide-gui %U"
    cp -r ${appimageContents}/usr/share/icons $out/share/

    runHook postInstall
  '';

  meta = {
    description = "ADE for working with a fleet of parallel coding agents";
    homepage = "https://github.com/stablyai/orca";
    changelog = "https://github.com/stablyai/orca/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "orca-ide";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
