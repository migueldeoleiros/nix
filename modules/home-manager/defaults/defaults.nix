{ config, pkgs, ... }:

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

    # Office - LibreOffice
    application/vnd.oasis.opendocument.text=writer.desktop
    application/vnd.oasis.opendocument.spreadsheet=calc.desktop
    application/vnd.oasis.opendocument.presentation=impress.desktop
    application/vnd.oasis.opendocument.graphics=draw.desktop
    application/msword=writer.desktop
    application/vnd.ms-excel=calc.desktop
    application/vnd.ms-powerpoint=impress.desktop
    application/vnd.openxmlformats-officedocument.wordprocessingml.document=writer.desktop
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet=calc.desktop
    application/vnd.openxmlformats-officedocument.presentationml.presentation=impress.desktop
    text/csv=calc.desktop
    text/plain=writer.desktop
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

    # Document Viewers
    application/pdf=okularApplication_pdf.desktop
    application/x-pdf=okularApplication_pdf.desktop
    application/epub+zip=okularApplication_epub.desktop
    image/vnd.djvu=okularApplication_djvu.desktop
    image/x-djvu=okularApplication_djvu.desktop
    application/postscript=okularApplication_ghostview.desktop
    application/vnd.ms-xpsdocument=okularApplication_xps.desktop
    application/oxps=okularApplication_xps.desktop

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
  '';

  xdg.configFile."mimeapps.list".force = true;

  home.sessionVariables = {
    BROWSER = "zen";
  };
}
