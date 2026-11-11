{ lib, pkgs, agentSecretsPackage }:
{ name, credentials, command, required ? true }:
let
  variables = builtins.attrNames credentials;
  readCredential = variable:
    [ "${agentSecretsPackage}/bin/agent-secrets" "read" ]
    ++ lib.optional (credentials.${variable}.trimEol or false) "--trim-eol"
    ++ [ credentials.${variable}.name ];
in
assert lib.assertMsg (variables != [ ] && lib.all
  (variable: builtins.match "[A-Z_][A-Z0-9_]*" variable != null
    && variable != "AGENT_CREDENTIALS_MISSING") variables)
  "Runtime credential mappings require explicit environment-variable names.";
assert lib.assertMsg (lib.all (binding:
  builtins.isAttrs binding && binding ? name && builtins.isString binding.name
  && builtins.isBool (binding.trimEol or false)) (builtins.attrValues credentials))
  "Runtime credential mappings require a name and optional boolean trimEol.";
pkgs.writeShellApplication {
  inherit name;
  runtimeInputs = [ pkgs.coreutils ];
  text = ''
    set +x
    export AGENT_CREDENTIALS_MISSING=
    ${lib.optionalString (!required) ''
      without_credentials() {
        export AGENT_CREDENTIALS_MISSING=${lib.escapeShellArg (lib.concatStringsSep " " variables)}
        ${lib.concatMapStringsSep "\n" (variable: "export ${variable}=/dev/null") variables}
        echo "Runtime credentials unavailable; continuing without optional integrations" >&2
        exec ${lib.escapeShellArgs command} "$@"
      }
    ''}
    runtime_dir="''${XDG_RUNTIME_DIR:-}"
    if [[ ! -d "$runtime_dir" || -L "$runtime_dir" || ! -O "$runtime_dir" ]] ||
       [[ "$(stat -c '%a' "$runtime_dir")" != 700 ]]; then
      ${if required then ''
        echo "Runtime credentials require a private, user-owned directory" >&2
        exit 1
      '' else ''
        without_credentials "$@"
      ''}
    fi
    umask 077
    if ! credential_directory="$(mktemp -d "$runtime_dir/agent-credentials.XXXXXX")"; then
      ${if required then "exit 1" else ''without_credentials "$@"''}
    fi
    child_pid=
    # Invoked indirectly by the EXIT trap.
    # shellcheck disable=SC2329
    cleanup() {
      if [[ -n "$child_pid" ]]; then
        kill -TERM "$child_pid" 2>/dev/null || true
      fi
      ${lib.concatMapStringsSep "\n" (variable:
        "rm -f -- \"$credential_directory/${variable}\"") variables}
      rmdir -- "$credential_directory" 2>/dev/null || true
    }
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    ${lib.concatMapStringsSep "\n" (variable: ''
      if ${lib.escapeShellArgs (readCredential variable)} > "$credential_directory/${variable}"; then
        export ${variable}="$credential_directory/${variable}"
      else
        ${if required then "exit 1" else ''
          rm -f -- "$credential_directory/${variable}"
          export ${variable}=/dev/null
          AGENT_CREDENTIALS_MISSING+="${variable} "
          echo "Optional runtime credential unavailable: ${variable}" >&2
        ''}
      fi
    '') variables}
    ${lib.escapeShellArgs command} "$@" <&0 &
    child_pid=$!
    status=0
    wait "$child_pid" || status=$?
    child_pid=
    exit "$status"
  '';
}
