# nix-config

My NixOS and Home Manager configuration.

## Machines

| Machine | Configuration |
| --- | --- |
| Framework | NixOS + Home Manager; current work laptop |
| Nitro | NixOS + Home Manager; NVIDIA/AMD laptop |
| Yoga | Standalone Home Manager on Linux |
| vm-shell | Standalone Home Manager for shell-focused Linux VMs |

## Apply changes

Run from this repository. Choose the command for the machine:

```bash
sudo nixos-rebuild switch --flake '.#miguel@framework'
sudo nixos-rebuild switch --flake '.#miguel@nitro'
home-manager switch --flake '.#miguel@yoga'
home-manager switch --flake '.#miguel@vm-shell'
```

Update packages and check the configuration:

```bash
nix flake update
nix flake check
```

To build a NixOS configuration without applying it, use `build` instead of `switch`.

## OpenCode and Orca

- Start a profile with `opencode-merlin`, `opencode-personal`, or `opencode-inditex`.
- `opencode` defaults to Merlin on laptops and Inditex on `vm-shell`.
- In Orca's **Settings > Agents > OpenCode**, set the command to `opencode-orca`
  and the default agent to `opencode`. This uses Personal on laptops and Inditex on VMs.
- Browser tools need Orca running locally or a paired remote environment.
- After applying OpenCode configuration changes, quit and restart OpenCode.

Sign in to the personal providers once per machine:

```bash
opencode-personal auth login --provider opencode-go
opencode-personal auth login --provider opencode
```

Keep credentials out of the repository. SSH, VPN, and Orca pairing are configured separately.

## Layout

- `hosts/` — machine-specific configuration
- `modules/home-manager/` — shared apps and user settings
- `modules/nixos/` — shared system settings
- `pkgs/` — custom packages
- `AGENTS.md` — conventions and configuration notes for coding agents
