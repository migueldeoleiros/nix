inherited_profile=
if [ -n "${PI_SUBAGENT_AGENT:-}" ] ||
   [ -n "${PI_SUBAGENT_SESSION:-}" ] ||
   [ -n "${PI_SUBAGENT_ID:-}" ]; then
  if [ -z "${PI_SUBAGENT_AGENT:-}" ] ||
     [ -z "${PI_SUBAGENT_SESSION:-}" ] ||
     [ -z "${PI_SUBAGENT_ID:-}" ] ||
     [ -z "${PI_CODING_AGENT_DIR:-}" ]; then
    echo "Invalid Pi child environment; refusing profile fallback." >&2
    exit 2
  fi
  inherited_agent_dir="$PI_CODING_AGENT_DIR"
@PROFILE_ROOTS@
  if [ -z "$inherited_profile" ]; then
    echo "Pi child agent directory is not a managed profile; refusing profile fallback." >&2
    exit 2
  fi
  case "$inherited_profile" in
@PROFILE_EXPORTS@
  esac
fi
