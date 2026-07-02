#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/hypr/screen_conf"

declare -A OPTIONS=(
  ["Custom Three Monitors"]="custom_three"
  ["Custom Three Monitors Right"]="custom_three_right"
  ["Mirror Display"]="mirror"
  ["Screen on Left"]="screen_on_left"
  ["Screen on Right"]="screen_on_right"
)

SELECTED_TEXT=$(printf "%s\n" "${!OPTIONS[@]}" | vicinae dmenu -p "Select screen configuration:")

if [[ -n "$SELECTED_TEXT" ]]; then
  SELECTED_FILE="${OPTIONS[$SELECTED_TEXT]}"
  echo "dofile(os.getenv(\"HOME\") .. \"/.config/hypr/screen_conf/$SELECTED_FILE.lua\")" > "$CONFIG_DIR/screen.lua"
  hyprctl reload
fi
