@CHILD_PROFILE@
unset PI_CODING_AGENT_DIR PI_CODING_AGENT_SESSION_DIR PI_PACKAGE_DIR
project_dir="$(cd -- "$PWD" && pwd -P)"
project_root="$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$project_dir")"
default_profile=@DEFAULT_PROFILE@
profile="$default_profile"
marker_found=0
dir="$project_dir"
while :; do
  marker="$dir/.pi-profile"
  if [ -e "$marker" ] || [ -L "$marker" ]; then
    if [ ! -f "$marker" ] || [ ! -r "$marker" ]; then
      echo "Pi profile marker must be a readable regular file: $marker" >&2
      exit 2
    fi
    if [ "$(wc -l < "$marker")" -gt 1 ]; then
      echo "Pi profile marker must contain one line: $marker" >&2
      exit 2
    fi
    profile="$(cat "$marker")"
    case "$profile" in
      merlin|personal|inditex) ;;
      *) echo "Invalid Pi profile in $marker; expected merlin, personal, or inditex." >&2; exit 2 ;;
    esac
    marker_found=1
    break
  fi
  if [ "$dir" = "$project_root" ]; then break; fi
  parent="${dir%/*}"
  if [ "$parent" = "$dir" ]; then break; fi
  dir="$parent"
done
if [ -n "$inherited_profile" ]; then
  profile="$inherited_profile"
elif [ "$marker_found" -eq 0 ]; then
  echo "No .pi-profile marker found for $project_dir; using default '$default_profile'." >&2
fi
enabled_profiles=@ENABLED_PROFILES@
case " $enabled_profiles " in
  *" $profile "*) ;;
  *) echo "Pi profile '$profile' is not enabled on this host." >&2; exit 2 ;;
esac
case "$profile" in
@PROFILE_CHOICES@
esac
@PI_LAUNCH@
