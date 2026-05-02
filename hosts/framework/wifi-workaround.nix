{ pkgs, ... }:

{
  # Temporary workaround for Jazztel_032 on Framework: pin the known-good AP radio and use a random client MAC.
  systemd.services.framework-wifi-workaround = {
    description = "Apply Framework Wi-Fi workaround";
    after = [ "NetworkManager.service" ];
    requires = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      if ${pkgs.networkmanager}/bin/nmcli -t -f NAME connection show | ${pkgs.gnugrep}/bin/grep -Fxq 'Jazztel_032'; then
        ${pkgs.networkmanager}/bin/nmcli connection modify 'Jazztel_032' \
          802-11-wireless.bssid 'A4:2B:B0:22:AF:BB' \
          802-11-wireless.cloned-mac-address 'random'
      fi
    '';
  };
}
