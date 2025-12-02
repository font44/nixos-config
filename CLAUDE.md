# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS configuration repository using Nix Flakes for system and home management. It configures a single host named "yakima" with a KDE Plasma 6 desktop environment.

## Key Commands

### Initial Installation
```sh
sudo nix run --experimental-features 'nix-command flakes' 'github:nix-community/disko/latest#disko-install' -- --flake .#yakima --disk main /dev/nvme0n1
```

### System Rebuild
```sh
sudo nixos-rebuild switch --flake .#yakima
```

### Update Flake Inputs
```sh
nix flake update
```

### Test Configuration Without Installing
```sh
sudo nixos-rebuild test --flake .#yakima
```

### Build Without Activating
```sh
sudo nixos-rebuild build --flake .#yakima
```

### Garbage Collection
```sh
sudo nix-collect-garbage -d
```

## Architecture

### Flake Structure

The configuration uses a standard NixOS flake with the following key inputs:
- **nixpkgs** (25.05): Primary package source
- **nixpkgs-unstable**: Used for newer versions of specific packages (kubectl, obsidian, talosctl)
- **home-manager** (release-25.05): User environment management
- **disko**: Declarative disk partitioning
- **sops-nix**: Secret management using SOPS
- **flox**: Package management tool
- **nix-ai-tools**: Provides claude-code

### File Organization

- **flake.nix**: Main entry point, defines system configuration and flake inputs
- **configuration.nix**: System-level configuration (services, packages, users)
- **home.nix**: User-level configuration for user "ketan" (programs, dotfiles)
- **hardware-configuration.nix**: Hardware-specific settings (auto-generated)
- **secrets/**: SOPS-encrypted secrets
- **.sops.yaml**: SOPS configuration with age keys

### Special Args Pattern

The flake passes `pkgs-unstable` as a special argument to modules, allowing selective use of unstable packages:
```nix
specialArgs = {
  inherit inputs;
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
};
```

Use `pkgs` for stable packages and `pkgs-unstable` for newer versions.

### Disk Configuration (Disko)

The system uses LUKS encryption on btrfs with the following subvolumes:
- `/root` → `/`
- `/home` → `/home`
- `/nix` → `/nix`
- `/swap` → `/.swap` (16GB swapfile)

All subvolumes use `compress=zstd` and `noatime` mount options.

### Secret Management

Secrets are managed with SOPS and age encryption:
- System secrets defined in `configuration.nix` (WireGuard keys)
- User secrets defined in `home.nix` (API keys, container registry credentials)
- Age keys derived from SSH host keys (`ssh-to-age`)
- Two age recipients: desktop (host key) and bitwarden (personal key)

To edit secrets:
```sh
sops secrets/default.yml
```

### Package Customization

Custom package wrappers are defined in configuration files:
- **my-kubernetes-helm**: Helm with plugins (secrets, diff, s3, git)
- **my-helmfile**: Helmfile configured to use the custom Helm wrapper

Pattern for wrapping packages with plugins:
```nix
let
  my-kubernetes-helm = with pkgs; wrapHelm kubernetes-helm {
    plugins = with pkgs.kubernetes-helmPlugins; [ ... ];
  };
  my-helmfile = pkgs.helmfile-wrapped.override {
    inherit (my-kubernetes-helm) pluginsDir;
  };
in
```

### User Management

- User: ketan
- Password: Hashed using yescrypt (`mkpasswd`)
- `mutableUsers = false`: Users managed declaratively only
- Sudo without password for wheel group
- Default shell: zsh

### Services

Key system services:
- **ollama**: LLM inference server (unstable version, exposed on 0.0.0.0)
- **open-webui**: Web UI for Ollama (auth disabled)
- **WireGuard**: VPN interface `wg0` (manual start via systemd)
- **SSH**: Password authentication disabled, key-only access
- **Avahi**: mDNS for local network discovery

WireGuard management:
```sh
sudo systemctl start wg-quick-wg0
sudo systemctl stop wg-quick-wg0
```

## Home Manager Integration

Home Manager is integrated as a NixOS module (not standalone). User configurations are in `home.nix` and applied to the user "ketan" via:
```nix
home-manager.users.ketan = import ./home.nix;
```

Key programs configured via Home Manager:
- **direnv**: Automatic environment activation
- **git**: User identity and default branch
- **neovim**: Default editor
- **tmux/zellij**: Terminal multiplexers
- **zsh**: Shell with syntax highlighting

## Testing Changes

When modifying configurations:
1. Make changes to relevant .nix files
2. Test with `sudo nixos-rebuild test --flake .#yakima` (doesn't add to boot menu)
3. If successful, apply with `sudo nixos-rebuild switch --flake .#yakima`
4. Commit changes to git

For home-manager only changes, the same commands work as home-manager is integrated into the NixOS configuration.
- Never add trivial code comments.