# Email setup

Auth: `~/.config/opencode/keys/main.json` (outside git, permissions `600`):

```json
{
  "address": "agent@example.com",
  "password": "YOUR-APP-PASSWORD",
  "allowedRecipients": ["*"]
}
```

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
