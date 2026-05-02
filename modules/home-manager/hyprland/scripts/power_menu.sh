#!/usr/bin/env bash

rofi_cmd(){
    rofi \
    -theme-str 'window {width: 300px; height: 300px;}' \
    -dmenu -i \
    -p "POWER MENU"
}

selection=$(echo -e "Poweroff\nReboot\nLock Screen\nExit Hyprland\n" | rofi_cmd)

case $selection in
    "Poweroff") hyprshutdown --post-cmd "systemctl poweroff" ;;
    "Reboot") hyprshutdown --post-cmd "systemctl reboot" ;;
    "Lock Screen") hyprlock ;;
    "Exit Hyprland") hyprshutdown ;;
esac
