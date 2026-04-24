{ config, pkgs, ... }:

{
  xdg.configFile."mimeapps.list".text = ''
    [Default Applications]
    # Browsers
    x-scheme-handler/http=firefox.desktop
    x-scheme-handler/https=firefox.desktop
    x-scheme-handler/ftp=firefox.desktop
    text/html=firefox.desktop
    application/xhtml+xml=firefox.desktop
    application/x-extension-htm=firefox.desktop
    application/x-extension-html=firefox.desktop
    application/x-extension-shtml=firefox.desktop
    application/x-extension-xht=firefox.desktop

    # Email
    x-scheme-handler/mailto=thunderbird.desktop
    message/rfc822=thunderbird.desktop
    text/vcard=thunderbird.desktop
    text/calendar=thunderbird.desktop

    # Office - LibreOffice
    application/vnd.oasis.opendocument.text=libreoffice-writer.desktop
    application/vnd.oasis.opendocument.spreadsheet=libreoffice-calc.desktop
    application/vnd.oasis.opendocument.presentation=libreoffice-impress.desktop
    application/vnd.oasis.opendocument.graphics=libreoffice-draw.desktop
    application/msword=libreoffice-writer.desktop
    application/vnd.ms-excel=libreoffice-calc.desktop
    application/vnd.ms-powerpoint=libreoffice-impress.desktop
    application/vnd.openxmlformats-officedocument.wordprocessingml.document=libreoffice-writer.desktop
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet=libreoffice-calc.desktop
    application/vnd.openxmlformats-officedocument.presentationml.presentation=libreoffice-impress.desktop
    text/csv=libreoffice-calc.desktop
    text/plain=libreoffice-writer.desktop
    application/rtf=libreoffice-writer.desktop

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
    application/pdf=okular.desktop
    image/vnd.djvu=okular.desktop
    application/postscript=okular.desktop

    # Communication
    x-scheme-handler/tg=telegramdesktop.desktop
    x-scheme-handler/telegram=telegramdesktop.desktop

    # Images
    image/jpeg=eog.desktop
    image/png=eog.desktop
    image/gif=eog.desktop
    image/bmp=eog.desktop
    image/webp=eog.desktop
    image/svg+xml=inkscape.desktop

    # Creative Tools
    image/x-xcf=gimp.desktop
    application/illustrator=inkscape.desktop
  '';

  xdg.configFile."mimeapps.list".force = true;

  home.sessionVariables = {
    BROWSER = "firefox";
  };
}