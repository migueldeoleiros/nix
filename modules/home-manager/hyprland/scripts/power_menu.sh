#!/usr/bin/env bash

selection=$(printf "Poweroff\nReboot\nLock Screen\nExit Hyprland\n" | vicinae dmenu -p "POWER MENU" -W 300 -H 300)

case $selection in
    "Poweroff") hyprshutdown --post-cmd "systemctl poweroff" ;;
    "Reboot") hyprshutdown --post-cmd "systemctl reboot" ;;
    "Lock Screen") hyprlock ;;
    "Exit Hyprland") hyprshutdown ;;
esac
