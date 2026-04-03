#!/usr/bin/env bash

# Simple script that toggles a commented line for switching between extending or sharing screen

FILE="$HOME/.config/hypr/hyprland.conf"
LINE_NUMBER=5

if sed -n "${LINE_NUMBER}p" "$FILE" | grep -q '^#'; then
  sed -i "${LINE_NUMBER}s/^#//" "$FILE"
else
  sed -i "${LINE_NUMBER}s/^/#/" "$FILE"
fi
