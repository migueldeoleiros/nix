{ pkgs, vars, host, ... }:

{
  users.users.${vars.user} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "lp" "input" "uinput" "seat" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    # Basic CLI utilities
    git
    neovim
    tmux
    tldr
    wget
    curl
    unzip
    zip
    file
    htop
    killall
    tree
    jq
    rsync
    ripgrep
    fd
    bc

    # Spell checking
    ispell

    # Network tools
    bind.dnsutils
    proton-vpn
    tor
    tor-browser

    # Development
    python3
    gcc
    gnumake
    libclang
    sbcl

    # System utilities
    wl-clipboard
    qemu
    exfatprogs
    ntfs3g
    bluez-tools
    overskride

    # Keyboard
    qmk
    vial
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    lmodern
    nerd-fonts.sauce-code-pro
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };

  boot.initrd.kernelModules = [
    "hidp" # for bluetooth keyboard
  ];

  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  networking = {
    hostName = host.hostName;
    networkmanager.enable = true;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };

  services.timesyncd.enable = true;
  time.timeZone = "Europe/Madrid";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "es_ES.UTF-8";
      LC_MEASUREMENT = "es_ES.UTF-8";
      LC_MONETARY = "es_ES.UTF-8";
      LC_PAPER = "es_ES.UTF-8";
      LC_TELEPHONE = "es_ES.UTF-8";
      LC_TIME = "en_IE.UTF-8";
    };
  };

  services = {
    printing.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    gvfs.enable = true;
    pulseaudio.enable = false;
    tor.enable = true;
  };
  security.rtkit.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        Enable = "Source,Sink,Media,Socket";
        ReconnectAttempts = 7;
        ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
        FastConnectable = true;
      };
      Policy.AutoEnable = true;
      Input.UserspaceHID = true;
    };
  };

  hardware.keyboard.qmk.enable = true;
  services.udev.packages = [ pkgs.vial ];

  services.seatd.enable = true;

  services.xserver.xkb = {
    layout = "us";
    options = "compose:ralt";
  };
  console.keyMap = "us";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.variables = {
    EDITOR = "nvim";
  };

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
    user.services.bluetooth-agent = {
      description = "Bluetooth pairing agent";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bluez-tools}/bin/bt-agent --capability=NoInputNoOutput";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };

  security.polkit.extraConfig = ''
     polkit.addRule(function(action, subject) {
      if (
        subject.isInGroup("users")
          && (
            action.id == "org.freedesktop.login1.reboot" ||
            action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
            action.id == "org.freedesktop.login1.power-off" ||
            action.id == "org.freedesktop.login1.power-off-multiple-sessions"
          )
        )
      {
        return polkit.Result.YES;
      }
    })
  '';

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
