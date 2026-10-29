{ pkgs, ... }:

{
  # Apply workarounds only to existing profiles; do not create profiles or reconnect Wi-Fi.
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

      # Office Wi-Fi: avoid failed 6 GHz roaming while retaining roaming between 5 GHz APs.
      # Match this profile by UUID so similarly named networks remain untouched.
      if ${pkgs.networkmanager}/bin/nmcli -g UUID connection show | ${pkgs.gnugrep}/bin/grep -Fxq '349008a7-d296-45cf-b528-0ab891f3b7fc'; then
        ${pkgs.networkmanager}/bin/nmcli connection modify uuid '349008a7-d296-45cf-b528-0ab891f3b7fc' \
          802-11-wireless.band 'a'
      fi
    '';
  };
}
