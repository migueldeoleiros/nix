# Embedded by writeShellApplication, which enables Bash strict mode.
# Load secrets at runtime, never into the Nix store or as shell code.
set +x
umask 077

fail() {
  echo "Email MCP: $*" >&2
  exit 1
}

check_credentials_file() {
  [[ -f "$secrets" && ! -L "$secrets" && -r "$secrets" ]] ||
    fail "create a private regular file at $secrets (see email-setup.md)"
  [[ "$(stat -c '%u' "$secrets")" == "$(id -u)" ]] ||
    fail "credentials must belong to the current user"

  local mode
  mode="$(stat -c '%a' "$secrets")"
  (( (8#$mode & 077) == 0 )) ||
    fail "credentials must not be accessible to group/others (chmod 600)"

  # Exactly one JSON object. Suppress jq errors: they might contain secrets.
  # Recipient commas/whitespace are forbidden because the server expects CSV.
  jq -se '
    def address: type == "string" and test("^[^@\\s]+@[^@\\s]+$");
    def password:
      type == "string" and length > 0 and (test("[\u0000-\u001f]") | not);
    def recipients:
      type == "array" and length <= 1000 and
      all(.[]; type == "string" and length > 0 and (test("[,\u0000-\u0020]") | not));

    length == 1 and (.[0] |
      type == "object" and
      ((keys - ["address", "password", "allowedRecipients"]) | length == 0) and
      (.address | address) and
      (.password | password) and
      ((.allowedRecipients // []) | recipients)
    )
  ' "$secrets" >/dev/null 2>&1 ||
    fail "invalid credentials JSON; expected address, password, optional allowedRecipients array"
}

load_account() {
  # Discard inherited endpoints, extra accounts, grants, and config overrides.
  local variable
  for variable in "${!MCP_EMAIL_SERVER_@}"; do
    unset "$variable"
  done

  export MCP_EMAIL_SERVER_CONFIG_PATH="$OPENCODE_EMAIL_RUNTIME_CONFIG"
  export MCP_EMAIL_SERVER_ACCOUNT_NAME=main
  export MCP_EMAIL_SERVER_FULL_NAME="Miguel Lopez's Agent"
  MCP_EMAIL_SERVER_EMAIL_ADDRESS="$(jq -r '.address' "$secrets")"
  MCP_EMAIL_SERVER_PASSWORD="$(jq -r '.password' "$secrets")"
  MCP_EMAIL_SERVER_ALLOWED_RECIPIENTS="$(jq -r '(.allowedRecipients // []) | join(",")' "$secrets")"
  export MCP_EMAIL_SERVER_EMAIL_ADDRESS MCP_EMAIL_SERVER_PASSWORD MCP_EMAIL_SERVER_ALLOWED_RECIPIENTS
}

configure_servers() {
  # Endpoints come from profiles.nix. Both protocols always verify certificates.
  export MCP_EMAIL_SERVER_IMAP_HOST="$OPENCODE_EMAIL_IMAP_HOST"
  export MCP_EMAIL_SERVER_IMAP_PORT="$OPENCODE_EMAIL_IMAP_PORT"
  export MCP_EMAIL_SERVER_IMAP_SSL="$OPENCODE_EMAIL_IMAP_SSL"
  export MCP_EMAIL_SERVER_IMAP_START_SSL="$OPENCODE_EMAIL_IMAP_START_SSL"
  export MCP_EMAIL_SERVER_IMAP_VERIFY_SSL=true

  export MCP_EMAIL_SERVER_SMTP_HOST="$OPENCODE_EMAIL_SMTP_HOST"
  export MCP_EMAIL_SERVER_SMTP_PORT="$OPENCODE_EMAIL_SMTP_PORT"
  export MCP_EMAIL_SERVER_SMTP_SSL="$OPENCODE_EMAIL_SMTP_SSL"
  export MCP_EMAIL_SERVER_SMTP_START_SSL="$OPENCODE_EMAIL_SMTP_START_SSL"
  export MCP_EMAIL_SERVER_SMTP_VERIFY_SSL=true
}

configure_policy() {
  # Keep the existing connector policy; individual agents narrow it further.
  # Empty recipients deny sending. Empty senders allow reading all inbound mail.
  export MCP_EMAIL_SERVER_ALLOWED_MUTATIONS=draft,send
  export MCP_EMAIL_SERVER_ACCOUNT_ALLOWED_MUTATIONS=draft,send
  export MCP_EMAIL_SERVER_ALLOW_PROTOCOL_COMMANDS=false
  export MCP_EMAIL_SERVER_ENABLE_ATTACHMENT_DOWNLOAD=false
  export MCP_EMAIL_SERVER_ENABLE_ATTACHMENT_CONTENT=false
  export MCP_EMAIL_SERVER_ALLOWED_SENDERS=""
  export MCP_EMAIL_SERVER_LOG_LEVEL=WARNING
}

secrets="$OPENCODE_EMAIL_SECRETS"
check_credentials_file
load_account
configure_servers
configure_policy

mkdir -p "$OPENCODE_EMAIL_DATA"
chmod 700 "$OPENCODE_EMAIL_DATA"
# Pin application and interpreter; uv still resolves transitive dependencies.
exec uvx --python python3.13 mcp-email-server@1.14.0 stdio
