#!/usr/bin/env bash

# Read the latest native Lua selection *after* locking. A delayed older request
# cannot overwrite a newer layout, and Super+B can call this without arguments.
exec 9>"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/bar.lock"
flock 9
state=$(hyprctl repl 'return monitor_bar_state()' 9>&-) || exit 1
monitor=${state%%$'\n'*}
[ -n "$monitor" ] || exit 0
roles=${state#*$'\n'}

# eww does not relocate an already-open window when its arguments change.
# Do not let an auto-started eww daemon inherit the coordinating lock.
eww close bar 9>&- 2>/dev/null || true
eww open bar --arg monitor="$monitor" 9>&-
eww update monitor_roles="$roles" 9>&-
