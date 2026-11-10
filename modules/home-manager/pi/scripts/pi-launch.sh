export PI_SKIP_VERSION_CHECK=1
export PI_TELEMETRY=0
export PI_SUBAGENT_MUX=tmux

load_orca_extensions=1
# Native commands dispatch on argv[0], before parsing session flags.
case "${1:-}" in
  auth|install|remove|update|list|config|mcp) load_orca_extensions=0 ;;
esac
for arg in "$@"; do
  case "$arg" in
    --no-extensions|-ne) load_orca_extensions=0; break ;;
  esac
done
if [ "$load_orca_extensions" -eq 1 ] && [ -n "${ORCA_PANE_KEY:-}" ]; then
  orca_source_dir="${ORCA_PI_SOURCE_AGENT_DIR:-$HOME/.pi/agent}"
  for extension in orca-agent-status.ts orca-prefill.ts orca-titlebar-spinner.ts; do
    extension_path="$orca_source_dir/extensions/$extension"
    if [ -f "$extension_path" ]; then
      extension_path="$(realpath -- "$extension_path")"
      active_extension="${PI_CODING_AGENT_DIR:-}/extensions/$extension"
      if [ -f "$active_extension" ] &&
         [ "$extension_path" = "$(realpath -- "$active_extension")" ]; then
        continue
      fi
      set -- --extension "$extension_path" "$@"
    fi
  done
fi

# Noninteractive commands run directly; existing tmux sessions must not nest.
if [ ! -t 0 ] || [ ! -t 1 ] || [ -n "${TMUX:-}" ]; then
  exec @PI_EXE@ "$@"
fi
status_file="$(mktemp)"
trap 'rm -f -- "$status_file"' EXIT
printf -v pi_command '%q ' @PI_EXE@ "$@"
printf -v status_path '%q' "$status_file"
pi_command+="; pi_status=\$?; printf '%s' \"\$pi_status\" > $status_path; exit \"\$pi_status\""

# A tmux server may retain stale ORCA_* variables. Clear names absent from this
# caller in the new child only; leave the server's global environment unchanged.
server_orca_names=()
while IFS= read -r name; do
  name="${name#-}"
  name="${name%%=*}"
  case "$name" in ORCA_*) server_orca_names+=("$name") ;; esac
done < <(tmux show-environment -g 2>/dev/null)
orca_names=()
orca_args=()
while IFS= read -r name; do
  case "$name" in ORCA_*)
    orca_names+=("$name")
    orca_args+=( -e "$name=${!name}" )
    ;;
  esac
done < <(compgen -e)
unset_names=()
for name in "${server_orca_names[@]}"; do
  if [[ ! " ${orca_names[*]} " == *" $name "* ]]; then
    unset_names+=("$name")
  fi
done
if [ "${#unset_names[@]}" -gt 0 ]; then
  printf -v orca_unset 'unset -- %q; ' "${unset_names[@]}"
  pi_command="$orca_unset$pi_command"
fi
if tmux new-session -s "pi-$$" \
  -e "PI_CODING_AGENT_DIR=$PI_CODING_AGENT_DIR" \
  -e "PI_CODING_AGENT_SESSION_DIR=$PI_CODING_AGENT_SESSION_DIR" \
  -e "PI_PACKAGE_DIR=$PI_PACKAGE_DIR" \
  -e "PI_SKIP_VERSION_CHECK=$PI_SKIP_VERSION_CHECK" \
  -e "PI_TELEMETRY=$PI_TELEMETRY" \
  -e "PI_SUBAGENT_MUX=$PI_SUBAGENT_MUX" \
  "${orca_args[@]}" \
  "$pi_command"; then
  tmux_status=0
else
  tmux_status=$?
fi
if [ -s "$status_file" ]; then
  exit "$(cat -- "$status_file")"
fi
exit "$tmux_status"
