#!/usr/bin/env bash

# Open bar on the preferred connected monitor: B -> C -> A.

monitor=$(~/.config/eww/scripts/main-monitor)

eww open bar --arg monitor="$monitor"
