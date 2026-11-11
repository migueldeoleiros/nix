# Email setup

Store the email account metadata and password as separate Secret Service notes
in Seahorse:

- `purelymail-address`: the account email address (single line)
- `purelymail-allowed-recipients`: a compact JSON array, e.g. `[]` or
  `["recipient@example.invalid"]`
- `purelymail-password`: the account password

The wrapper retrieves these privately by exact note name, with trailing CR/LF
removed for the single-line metadata (`purelymail-address`,
`purelymail-allowed-recipients`) and the password (`purelymail-password`)
preserved verbatim. Values are passed only to the email MCP process. Agents
never read credential values directly, even though the underlying lookups are
generic name-based reads. No `mail.json` file is needed. An empty recipient
array denies sending; include `"*"` only when you explicitly intend to allow
any recipient.

Server: `personal.email` in `modules/home-manager/opencode/profiles.nix`:

```nix
email = {
  imapHost = "imap.purelymail.com";
  imapPort = 993;
  imapTls = "implicit";
  smtpHost = "smtp.purelymail.com";
  smtpPort = 465;
  smtpTls = "implicit";
};
```

TLS: `implicit` or `starttls` (usually SMTP port `587`).
