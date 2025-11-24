{ config, pkgs, lib, inputs, vars, ... }:

{
  imports = (
  #   import ../modules/vm ++
      import ../modules/syncthing ++
     import ../modules/powersaver
  );

  # Define a user account
  users.users.${vars.user} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "lp" "input" "uinput" "seat"];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    neovim
    tldr
    eza
    trash-cli
    tmux
    gh
    neofetch
    python3
    wine
    bat
    unzip
    wget
    ocaml
    ocamlPackages.utop
    emacsPackages.tuareg
    gcc
    sbcl
    libclang
    file
    wl-clipboard
    qemu
    htop
    texlive.combined.scheme-full
    gnumake
    exfatprogs
    ntfs3g
    zip
    pandoc
    killall

    # Hyprland ecosystem (config managed via stow in .dotfiles)
    dunst
    eww
    pyprland
    swww
    cliphist
    playerctl
    brightnessctl
    wayshot
    slurp
    networkmanager_dmenu
    bibata-cursors
    jq
    alsa-utils
    socat
    unixtools.ifconfig
  ];

  # fonts
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

  # Bootloader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };

  # Garbage Collection
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Networking
  networking = {
    hostName = "nitro";
    # wireless.enable = true;
    networkmanager.enable = true;
  };

  # Set your time.
  services.timesyncd.enable = true;
  time.timeZone = "Europe/Madrid";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "es_ES.UTF-8";
      LC_MEASUREMENT = "es_ES.UTF-8";
      LC_MONETARY = "es_ES.UTF-8";
      LC_PAPER = "es_ES.UTF-8";
      LC_TELEPHONE = "es_ES.UTF-8";
      LC_TIME = "es_ES.UTF-8";
    };
  };

  services = {
    printing = {
      enable = true; 
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      #jack.enable = true;
    };
    gvfs.enable = true;
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Enable sound with PipeWire
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true; 
    package = pkgs.bluez;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
  services.blueman.enable = true;

  # Enable seatd for Wayland compositors (sway, etc.)
  services.seatd.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    options = "compose:ralt";
  };

  # Configure console keymap
  console.keyMap = "us";

  # Enable Hyprland (config managed via stow in .dotfiles)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Set environment variables
  environment.variables = {
    EDITOR = "nvim";
  };

  # NVIDIA/Wayland environment variables
  environment.sessionVariables = {
    # Disable hardware cursors if issues occur
    # WLR_NO_HARDWARE_CURSORS = "1";
    # Let Hyprland auto-detect which GPU to use per display
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # polkit
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

  # Nvidia GPU
  # Enable graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  boot.kernelParams = [
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia-drm.modeset=1"
  ];

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = { # Modesetting is required.
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      sync.enable = true;
      # offload = {
      #   enable = true;
      #   enableOffloadCmd = true;
      # };
      amdgpuBusId = "PCI:1:0:0";
      nvidiaBusId = "PCI:5:0:0";
    };
  };

  system.stateVersion = "23.05";

  home-manager.users.${vars.user} = {
    imports = (
  #   import ../modules/qutebrowser ++
      import ../modules/shell ++
      import ../modules/rofi ++
      import ../modules/gtk ++
      import ../modules/bitwarden ++
      import ../modules/yazi ++
      import ../modules/fcitx5 ++
      import ../modules/games ++
      import ../modules/home
    );

    home = {
      stateVersion = "23.05";
    };

    programs = {
      home-manager.enable = true;
    };
  };
}
