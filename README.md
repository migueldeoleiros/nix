# nix-config

NixOS and home-manager configuration for my machines.

## Hosts

- **nitro** - NixOS system with home-manager as a module. Laptop with NVIDIA/AMD hybrid graphics
- **yoga** - Standalone home-manager config for a non-NixOS machine (Arch).

## Structure

```
hosts/          # per-machine configs
  nitro/        # NixOS system + user config
  yoga/         # home-manager only
modules/
  home-manager/ # user-level modules
  nixos/        # system-level modules
pkgs/           # custom package builds
```

## Usage

Rebuild NixOS (nitro):
```bash
sudo nixos-rebuild switch --flake .#miguel
```

Apply home-manager (yoga):
```bash
home-manager switch --flake .#miguel@yoga
```

Update flake inputs:
```bash
nix flake update
```
