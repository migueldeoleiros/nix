#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/hypr/screen_conf"

declare -A OPTIONS=(
  ["Custom Three Monitors"]="custom_three.conf"
  ["Mirror Display"]="mirror.conf"
  ["Screen on Left"]="screen_on_left.conf"
  ["Screen on Right"]="screen_on_right.conf"
)

SELECTED_TEXT=$(printf "%s\n" "${!OPTIONS[@]}" | rofi -dmenu -p "Select screen configuration:")

if [[ -n "$SELECTED_TEXT" ]]; then
  SELECTED_FILE="${OPTIONS[$SELECTED_TEXT]}"
  SOURCE_LINE="source = $CONFIG_DIR/$SELECTED_FILE"
  echo "$SOURCE_LINE" > "$CONFIG_DIR/screen.conf"
fi
