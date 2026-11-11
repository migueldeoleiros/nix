# Embedded by writeShellApplication, which enables Bash strict mode.
# Retrieve account metadata and password privately at runtime.
set +x
umask 077

fail() {
  echo "Email MCP: $*" >&2
  exit 1
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

  local address recipients_json password
  address="$("$OPENCODE_EMAIL_CREDENTIAL_HELPER" read --trim-eol purelymail-address)" ||
    fail "could not retrieve email address from the keyring"
  [[ "$address" =~ ^[^@[:space:]]+@[^@[:space:]]+$ ]] ||
    fail "keyring returned an invalid email address"

  recipients_json="$("$OPENCODE_EMAIL_CREDENTIAL_HELPER" read --trim-eol purelymail-allowed-recipients)" ||
    fail "could not retrieve email recipient policy from the keyring"
  # The server expects CSV; reject commas and whitespace within each address.
  printf '%s' "$recipients_json" | jq -es '
    def recipients:
      type == "array" and length <= 1000 and
      all(.[]; type == "string" and length > 0 and (test("[,\u0000-\u0020]") | not));
    length == 1 and (.[0] | recipients)
  ' >/dev/null 2>&1 || fail "keyring returned an invalid email recipient policy"
  MCP_EMAIL_SERVER_EMAIL_ADDRESS="$address"
  MCP_EMAIL_SERVER_ALLOWED_RECIPIENTS="$(printf '%s' "$recipients_json" | jq -r 'join(",")')"

  password="$("$OPENCODE_EMAIL_CREDENTIAL_HELPER" read purelymail-password)" ||
    fail "could not retrieve email password from the keyring"
  [[ -n "$password" && ! "$password" =~ [[:cntrl:]] ]] ||
    fail "keyring returned an invalid email password"
  MCP_EMAIL_SERVER_PASSWORD="$password"
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

load_account
configure_servers
configure_policy

mkdir -p "$OPENCODE_EMAIL_DATA"
chmod 700 "$OPENCODE_EMAIL_DATA"
# Pin application and interpreter; uv still resolves transitive dependencies.
exec uvx --python python3.13 mcp-email-server@1.14.0 stdio
