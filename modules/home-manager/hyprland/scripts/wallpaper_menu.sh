#!/usr/bin/env bash

wallpaper_dir="$HOME/wallpapers"
wallpaper_script="$HOME/.config/hypr/wallpaper.sh"
transition="center"

get_selection(){
    local dir_file="$1"

    if [[ -d $dir_file ]]; then
        selected=$(find "$dir_file" -maxdepth 1 -mindepth 1 -printf "%f\n" | sort | vicinae dmenu -p "SELECT WALLPAPER" -W 500 -H 500)
        if [[ "$selected" == "" ]]; then
            echo ""
        else
            get_selection "$dir_file/$selected"
        fi
    elif [[ -f $dir_file ]]; then
        echo "$dir_file"
    else
        echo ""
    fi
}

selection=$(get_selection "$wallpaper_dir")
display=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
display_line=$(grep -n "$display" "$wallpaper_script" 2>/dev/null | cut -d: -f1)

if [[ -n $selection ]]; then
    awww img "$selection" --transition-type "$transition" -o "$display"
    if [[ -z $display_line ]]; then
        echo "awww img $selection -o $display" >> "$wallpaper_script"
    else
        sed -i "${display_line}s|.*|awww img $selection -o $display|" "$wallpaper_script"
    fi
    chmod +x "$wallpaper_script"
fi
