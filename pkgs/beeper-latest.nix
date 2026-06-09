{ lib, writeShellApplication, curl, appimage-run, makeDesktopItem, symlinkJoin }:

let
  pname = "beeper-latest";

  beeper = writeShellApplication {
    name = "beeper";
    runtimeInputs = [ curl appimage-run ];
    text = ''
      set -euo pipefail

      url="https://api.beeper.com/desktop/download/linux/x64/stable/com.automattic.beeper.desktop"
      cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/beeper-latest"
      appimage="$cache_dir/Beeper-x86_64.AppImage"
      stamp="$cache_dir/last-check"
      tmp="$cache_dir/.Beeper-x86_64.AppImage.tmp"
      desktop_file="''${XDG_DATA_HOME:-$HOME/.local/share}/applications/Beeper.desktop"

      write_desktop_entry() {
        icon="beeper"
        if [ -e "$HOME/.local/share/icons/beeper.png" ]; then
          icon="$HOME/.local/share/icons/beeper.png"
        fi

        mkdir -p "$(dirname "$desktop_file")"
        printf '%s\n' \
          '[Desktop Entry]' \
          'Name=Beeper' \
          'Exec=beeper %U' \
          'Type=Application' \
          'Terminal=false' \
          'Comment=Universal chat app' \
          'Categories=Network;InstantMessaging;Chat;' \
          'MimeType=x-scheme-handler/beeper;' \
          'StartupWMClass=Beeper' \
          'StartupNotify=true' \
          "Icon=$icon" \
          > "$desktop_file"
      }

      mkdir -p "$cache_dir"

      should_update=0
      if [ ! -s "$appimage" ]; then
        should_update=1
      elif [ ! -e "$stamp" ]; then
        should_update=1
      elif [ $(( $(date +%s) - $(stat -c %Y "$stamp") )) -gt 86400 ]; then
        should_update=1
      fi

      if [ "$should_update" -eq 1 ]; then
        echo "Checking Beeper AppImage release..." >&2
        if curl --fail --location --show-error --output "$tmp" "$url"; then
          chmod +x "$tmp"
          mv "$tmp" "$appimage"
          touch "$stamp"
        else
          rm -f "$tmp"
          if [ ! -s "$appimage" ]; then
            exit 1
          fi
          echo "Beeper update failed; using cached AppImage." >&2
        fi
      fi

      write_desktop_entry
      (
        i=0
        while [ "$i" -lt 15 ]; do
          sleep 1
          write_desktop_entry
          i=$((i + 1))
        done
      ) >/dev/null 2>&1 &

      exec appimage-run "$appimage" "$@"
    '';
  };

  desktopItem = makeDesktopItem {
    name = "Beeper";
    desktopName = "Beeper";
    genericName = "Messaging client";
    comment = "Universal chat app";
    exec = "beeper %U";
    terminal = false;
    categories = [ "Network" "InstantMessaging" "Chat" ];
    startupWMClass = "Beeper";
  };
in
symlinkJoin {
  inherit pname;
  version = "latest";
  paths = [ beeper desktopItem ];

  meta = {
    description = "Beeper desktop launcher that downloads the latest upstream AppImage at runtime";
    homepage = "https://www.beeper.com/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "beeper";
  };
}
