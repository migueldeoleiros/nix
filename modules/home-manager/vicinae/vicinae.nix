{ config, lib, pkgs, inputs, vars, ... }:

{
  home = {
    packages = with pkgs; [
      pulseaudio
    ];
  };
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
    };
    settings = {
      close_on_focus_loss= false;
      consider_preedit= false;
      favicon_service= "twenty";
      font= {
        normal = {
          size= 11.5;
        };
      };
      keybinding= "default";
      keybinds= {
      };
      pop_to_root_on_close= true;
      search_files_in_root= false;
      theme= {
        dark= {
          name= "deep-dark";
        };
        light= {
          name= "deep-dark";
        };
      };
      launcher_window= {
        opacity= 1.0;
        size= {
          width= 900;
          height= 560;
        };
        client_side_decorations= {
          enabled= true;
          rounding= 10;
        };
      };
    };

    extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
      nix
      # bluetooth
      wifi-commander
      player-pilot
      pulseaudio
      process-manager
    ];
  };

  xdg.dataFile."vicinae/themes/adwaita-dark.toml".source = ./themes/adwaita-dark.toml;
  xdg.dataFile."vicinae/themes/deep-dark.toml".source = ./themes/deep-dark.toml;

  systemd.user.services.vicinae.Service = {
    Environment = "PATH=%h/.local/bin:%h/programs/flutter/bin:%h/.cargo/bin:/run/wrappers/bin:%h/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:%h/.nix-profile/bin:/nix/profile/bin:%h/.local/state/nix/profile/bin:/etc/profiles/per-user/${vars.user}/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
    ExecStart = lib.mkForce "${config.programs.vicinae.package}/bin/vicinae server --replace";
  };
}
