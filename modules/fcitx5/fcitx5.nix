{ config, pkgs, lib, vars, ... }:

{
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc        # Japanese input
      fcitx5-gtk         # GTK integration
      qt6Packages.fcitx5-configtool  # GUI configuration tool
    ];
  };

  # Wayland environment variables for fcitx5
  home.sessionVariables = {
    QT_IM_MODULE = "fcitx";
    QT_IM_MODULES="wayland;fcitx;ibus";
    XMODIFIERS = "@im=fcitx";
    GLFW_IM_MODULE = "ibus";
  };

  # fcitx5 configuration files
  home.file.".config/fcitx5/profile".text = ''
    [Groups/0]
    # Group Name
    Name=Default
    # Layout
    Default Layout=us
    # Default Input Method
    DefaultIM=keyboard-us

    [Groups/0/Items/0]
    # Name
    Name=keyboard-us
    # Layout
    Layout=

    [Groups/0/Items/1]
    # Name
    Name=mozc
    # Layout
    Layout=

    [Groups/0/Items/2]
    # Name
    Name=keyboard-es
    # Layout
    Layout=

    [GroupOrder]
    0=Default
  '';

  home.file.".config/fcitx5/config".text = ''
    [Hotkey]
    # Enumerate when press trigger key repeatedly
    EnumerateWithTriggerKeys=True
    # Enumerate Input Method Forward
    EnumerateForwardKeys=
    # Enumerate Input Method Backward
    EnumerateBackwardKeys=
    # Skip first input method while enumerating
    EnumerateSkipFirst=False
    # Time limit in milliseconds for triggering modifier key shortcuts
    ModifierOnlyKeyTimeout=250

    [Hotkey/TriggerKeys]
    0=Control+space

    [Hotkey/AltTriggerKeys]
    0=Super+Super_R

    [Hotkey/EnumerateGroupForwardKeys]
    0=

    [Hotkey/EnumerateGroupBackwardKeys]
    0=

    [Hotkey/PrevPage]
    0=Up

    [Hotkey/NextPage]
    0=Down

    [Hotkey/PrevCandidate]
    0=Shift+Tab

    [Hotkey/NextCandidate]
    0=Tab

    [Hotkey/TogglePreedit]
    0=Control+Alt+P

    [Behavior]
    # Active By Default
    ActiveByDefault=False
    # Reset state on Focus In
    resetStateWhenFocusIn=No
    # Share Input State
    ShareInputState=No
    # Show preedit in application
    PreeditEnabledByDefault=True
    # Show Input Method Information when switch input method
    ShowInputMethodInformation=True
    # Show Input Method Information when changing focus
    showInputMethodInformationWhenFocusIn=False
    # Show compact input method information
    CompactInputMethodInformation=True
    # Show first input method information
    ShowFirstInputMethodInformation=True
    # Default page size
    DefaultPageSize=5
    # Override Xkb Option
    OverrideXkbOption=False
    # Custom Xkb Option
    CustomXkbOption=
    # Force Enabled Addons
    EnabledAddons=
    # Force Disabled Addons
    DisabledAddons=
    # Preload input method to be used by default
    PreloadInputMethod=True
    # Allow input method in the password field
    AllowInputMethodForPassword=False
    # Show preedit text when typing password
    ShowPreeditForPassword=False
    # Interval of saving user data in minutes
    AutoSavePeriod=30
  '';
}
