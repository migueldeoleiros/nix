#!/usr/bin/env bash

# Simple script that moves hyprland workspaces around connected monitors

MONITORS=$(hyprctl monitors -j | jq -r '.[] | .id')
CURRENT=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .id')
INDEX=$(echo "$MONITORS" | tr ' ' '\n' | grep -n "$CURRENT" | cut -d: -f1)
NEXT_INDEX=$(( (INDEX) % $(echo "$MONITORS" | wc -w) ))
NEXT_MONITOR=$(echo "$MONITORS" | tr ' ' '\n' | head -n $((NEXT_INDEX + 1)) | tail -n 1)
hyprctl dispatch movecurrentworkspacetomonitor "$NEXT_MONITOR"
