#!/usr/bin/env bash

program=$(ps -u "$USER" -o comm,pid | awk 'NR > 1' | rofi -dmenu -i -p "kill")
pid=$(echo "$program" | awk '{print $NF}')
if [[ -n "$pid" ]]; then
    kill "$pid"
fi
