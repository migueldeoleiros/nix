{ config, pkgs, lib }:
{ imapHost, smtpHost, imapPort ? 993, smtpPort ? 465,
  imapTls ? "implicit", smtpTls ? "implicit" }:
assert lib.assertMsg (lib.elem imapTls [ "implicit" "starttls" ] && lib.elem smtpTls [ "implicit" "starttls" ])
  "Email TLS mode must be implicit or starttls; plaintext is unsupported.";
let
  # Immutable, account-free config prevents merging a user's other mail accounts
  # or selecting a managed catalog via a writable bootstrap sidecar.
  runtimeConfig = pkgs.writeText "opencode-email.toml" ''
    db_location = ${builtins.toJSON "${config.xdg.dataHome}/opencode-email/db.sqlite3"}
    allowed_mutations = ["draft", "send"]
    enable_attachment_download = true
    enable_attachment_content = true
  '';
  wrapper = pkgs.writeShellApplication {
    name = "opencode-email-mcp";
    runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.uv pkgs.python313 ];
    text = ''
      export OPENCODE_EMAIL_SECRETS=${lib.escapeShellArg "${config.xdg.configHome}/opencode/keys/mail.json"}
      export OPENCODE_EMAIL_RUNTIME_CONFIG=${runtimeConfig}
      export OPENCODE_EMAIL_DATA=${lib.escapeShellArg "${config.xdg.dataHome}/opencode-email"}
      export OPENCODE_EMAIL_IMAP_HOST=${lib.escapeShellArg imapHost}
      export OPENCODE_EMAIL_IMAP_PORT=${lib.escapeShellArg (toString imapPort)}
      export OPENCODE_EMAIL_SMTP_HOST=${lib.escapeShellArg smtpHost}
      export OPENCODE_EMAIL_SMTP_PORT=${lib.escapeShellArg (toString smtpPort)}
      export OPENCODE_EMAIL_IMAP_SSL=${lib.boolToString (imapTls == "implicit")}
      export OPENCODE_EMAIL_IMAP_START_SSL=${lib.boolToString (imapTls == "starttls")}
      export OPENCODE_EMAIL_SMTP_SSL=${lib.boolToString (smtpTls == "implicit")}
      export OPENCODE_EMAIL_SMTP_START_SSL=${lib.boolToString (smtpTls == "starttls")}
      ${builtins.readFile ./scripts/email-mcp.sh}
    '';
  };
in {
  inherit wrapper;
  mcp = {
    type = "local";
    command = [ "${wrapper}/bin/opencode-email-mcp" ];
    disabled = false;
    codemode = false;
    timeout = { startup = 120000; catalog = 60000; execution = 120000; };
  };
}
