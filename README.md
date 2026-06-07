# nix-config

Nix flake for my NixOS systems and standalone Home Manager machines.

## Targets

- `.#miguel@nitro` - NixOS system with Home Manager as a NixOS module. NVIDIA/AMD hybrid laptop. Uses the pinned `nixpkgs-nitro-kernel` input for kernel/firmware support.
- `.#miguel@framework` - NixOS system with Home Manager as a NixOS module. Framework laptop config for work with Framework-specific hardware modules.
- `.#miguel@yoga` - standalone Home Manager config for a non-NixOS generic Linux machine. There is no NixOS config for this host.

## Structure

```text
flake.nix                 # inputs, host records, and flake outputs
hosts/                    # per-machine wiring
  nitro/                  # NixOS system + Home Manager user config
  framework/              # NixOS system + Home Manager user config
  yoga/                   # standalone Home Manager only
modules/
  home-manager/           # shared user-level modules
  nixos/                  # shared system-level modules
pkgs/                     # custom package builds loaded with pkgs.callPackage
```

Host files build imports by concatenating module-directory `default.nix` lists. 
Reusable modules should usually be added to the relevant module directory and its `default.nix`.

## Usage

Rebuild NixOS targets:

```bash
sudo nixos-rebuild switch --flake '.#miguel@nitro'
sudo nixos-rebuild switch --flake '.#miguel@framework'
```

Apply standalone Home Manager:

```bash
home-manager switch --flake '.#miguel@yoga'
```

Update flake inputs:

```bash
nix flake update
```

Optional checks/builds:

```bash
nix flake check
nix build '.#nixosConfigurations."miguel@nitro".config.system.build.toplevel'
nix build '.#nixosConfigurations."miguel@framework".config.system.build.toplevel'
```

## Configuration notes

- Hyprland/UI modules depend on host records in `flake.nix` for monitor names, resolutions, keyboard layout, `hasNvidia`, `tabletOutput`, `defaultScreenConfig`, and `batteryId`.
- Hyprland screen layout is intentionally mutable: generated variables are managed from Home Manager, while the runtime screen layout file is only created when missing so local display changes can survive switches.
- For API keys that are used by OpenCode or other sofware, you would need to add a file with the key before building.
