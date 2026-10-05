{ config, pkgs, ... }:

let
  editorMimeTypes = [
    "text/plain"
    "application/x-desktop"
    "text/markdown"
    "application/json"
    "application/x-yaml"
    "application/xml"
    "application/toml"
    "application/x-shellscript"
    "text/x-python"
    "text/x-c"
    "text/x-c++"
    "text/x-java"
    "application/javascript"
    "text/css"
  ];
  editorDefaultApplications = builtins.concatStringsSep "\n" (map (mimeType: "${mimeType}=emacs.desktop") editorMimeTypes);
  editorAddedAssociations = builtins.concatStringsSep "\n" (map (mimeType: "${mimeType}=emacs.desktop;") editorMimeTypes);
in
{
  xdg.configFile."mimeapps.list".text = ''
    [Default Applications]
    # Browsers
    x-scheme-handler/http=zen.desktop
    x-scheme-handler/https=zen.desktop
    x-scheme-handler/ftp=zen.desktop
    text/html=zen.desktop
    application/xhtml+xml=zen.desktop
    application/x-extension-htm=zen.desktop
    application/x-extension-html=zen.desktop
    application/x-extension-shtml=zen.desktop
    application/x-extension-xht=zen.desktop

    # Email
    x-scheme-handler/mailto=thunderbird.desktop
    message/rfc822=thunderbird.desktop
    text/vcard=thunderbird.desktop
    text/calendar=thunderbird.desktop

    # Editors
    ${editorDefaultApplications}

    # Office - LibreOffice
    application/vnd.oasis.opendocument.text=writer.desktop
    application/vnd.oasis.opendocument.text-template=writer.desktop
    application/vnd.oasis.opendocument.spreadsheet=calc.desktop
    application/vnd.oasis.opendocument.spreadsheet-template=calc.desktop
    application/vnd.oasis.opendocument.presentation=impress.desktop
    application/vnd.oasis.opendocument.presentation-template=impress.desktop
    application/vnd.oasis.opendocument.graphics=draw.desktop
    application/msword=writer.desktop
    application/vnd.ms-excel=calc.desktop
    application/vnd.ms-powerpoint=impress.desktop
    application/vnd.openxmlformats-officedocument.wordprocessingml.document=writer.desktop
    application/vnd.openxmlformats-officedocument.wordprocessingml.template=writer.desktop
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet=calc.desktop
    application/vnd.openxmlformats-officedocument.spreadsheetml.template=calc.desktop
    application/vnd.openxmlformats-officedocument.presentationml.presentation=impress.desktop
    application/vnd.openxmlformats-officedocument.presentationml.template=impress.desktop
    application/vnd.ms-word.document.macroEnabled.12=writer.desktop
    application/vnd.ms-excel.sheet.macroEnabled.12=calc.desktop
    application/vnd.ms-powerpoint.presentation.macroEnabled.12=impress.desktop
    text/csv=calc.desktop
    text/tab-separated-values=calc.desktop
    application/rtf=writer.desktop

    # Media Players
    video/mpeg=mpv.desktop
    video/mp4=mpv.desktop
    video/x-matroska=mpv.desktop
    video/webm=mpv.desktop
    video/quicktime=mpv.desktop
    video/x-msvideo=mpv.desktop
    audio/mpeg=mpv.desktop
    audio/mp4=mpv.desktop
    audio/ogg=mpv.desktop
    audio/flac=mpv.desktop
    audio/wav=mpv.desktop
    audio/aac=mpv.desktop
    audio/opus=mpv.desktop
    audio/x-wav=mpv.desktop
    video/ogg=mpv.desktop
    video/x-ms-wmv=mpv.desktop

    # Document Viewers
    application/pdf=org.gnome.Papers.desktop
    application/x-pdf=org.gnome.Papers.desktop
    image/vnd.djvu=org.gnome.Papers.desktop
    image/x-djvu=org.gnome.Papers.desktop

    # Communication
    x-scheme-handler/tg=org.telegram.desktop.desktop
    x-scheme-handler/telegram=org.telegram.desktop.desktop

    # Images
    image/jpeg=org.gnome.eog.desktop
    image/png=org.gnome.eog.desktop
    image/gif=org.gnome.eog.desktop
    image/bmp=org.gnome.eog.desktop
    image/webp=org.gnome.eog.desktop
    image/svg+xml=org.inkscape.Inkscape.desktop

    # Creative Tools
    image/x-xcf=gimp.desktop
    application/illustrator=org.inkscape.Inkscape.desktop

    # File manager
    inode/directory=org.gnome.Nautilus.desktop
    application/zip=org.gnome.Nautilus.desktop
    application/x-7z-compressed=org.gnome.Nautilus.desktop
    application/x-tar=org.gnome.Nautilus.desktop
    application/gzip=org.gnome.Nautilus.desktop
    application/x-bzip2=org.gnome.Nautilus.desktop
    application/x-xz=org.gnome.Nautilus.desktop
    application/zstd=org.gnome.Nautilus.desktop
    application/vnd.rar=org.gnome.Nautilus.desktop

    [Added Associations]
    # Emacs does not advertise every editor MIME type above in its desktop file.
    ${editorAddedAssociations}
  '';

  xdg.configFile."mimeapps.list".force = true;

  home.sessionVariables = {
    BROWSER = "zen";
  };
}
