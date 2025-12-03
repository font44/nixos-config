# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a modular NixOS configuration repository using Nix Flakes for multi-host system and home management. The architecture is designed to support multiple hosts with shared modules and user configurations.

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

### Modular Structure

The configuration uses a multi-layer architecture:

**Flake Entry (flake.nix)**
- Defines flake inputs and outputs
- Calls `lib.mkSystem` to construct each host

**Library Layer (lib/)**
- `lib/default.nix`: Exports utility functions
- `lib/mkSystem.nix`: Core system builder that:
  - Accepts parameters: hostname, system, users, isDesktop, isServer, isAmdGpu
  - Creates both stable `pkgs` and `pkgs-unstable` package sets
  - Passes `pkgs-unstable` and other args via specialArgs
  - Imports all modules from `modules/`
  - Loads host-specific configuration from `hosts/${hostname}/`
  - Conditionally enables modules based on boolean flags
  - Sets up home-manager for all specified users

**Modules Layer (modules/)**
- Each module uses the `my.${module-name}.enable` option pattern
- `modules/default.nix`: Imports all available modules
- Individual modules define `options.my.${name}` for configuration
- All modules use `mkIf cfg.enable` for conditional activation
- Available modules:
  - `base.nix`: Core locale configuration (always enabled by default)
  - `nix.nix`: Nix daemon and flake settings
  - `networking.nix`: Network configuration with NetworkManager
  - `users.nix`: User account management with `my.users.users.<name>` options
  - `desktop.nix`: KDE Plasma desktop environment
  - `gaming.nix`: Gaming-related packages and configurations
  - `local-llm.nix`: Ollama and Open WebUI services
  - `dev-setup.nix`: Development tools and environments
  - `home.nix`: Base home-manager configurations
  - `home-desktop.nix`: Desktop-specific home-manager settings
  - `amd-gpu.nix`: AMD GPU support

**Host Layer (hosts/${hostname}/)**
- `configuration.nix`: Host-specific settings (timezone, user assignments, services)
- `hardware-configuration.nix`: Auto-generated hardware configuration
- `disko.nix`: Optional disk partitioning schema (LUKS + btrfs)

**User Layer (users/)**
- `user.nix`: Reusable user configuration template
- Takes parameters: name, email, fullName
- Defines home-manager configuration with git, sops secrets, session variables
- Applied to users via home-manager in mkSystem

### Special Args Pattern

`mkSystem.nix` creates and passes these special arguments to all modules:
```nix
specialArgs = {
  inherit inputs pkgs-unstable hostname;
};
```

Use `pkgs` for stable packages (25.05) and `pkgs-unstable` for newer versions.

### Module Options Pattern

All modules follow this structure:
```nix
{ config, lib, ... }:

with lib;

let
  cfg = config.my.module-name;
in {
  options.my.module-name = {
    enable = mkEnableOption "description";
    # additional options
  };

  config = mkIf cfg.enable {
    # implementation
  };
}
```

### Adding a New Host

To add a new host:
1. Create `hosts/${hostname}/configuration.nix` with host-specific settings
2. Create `hosts/${hostname}/hardware-configuration.nix` (can be auto-generated)
3. Optionally create `hosts/${hostname}/disko.nix` for declarative partitioning
4. Add host to flake.nix using `lib.mkSystem`:
```nix
nixosConfigurations.newhostname = lib.mkSystem {
  hostname = "newhostname";
  system = "x86_64-linux";
  isDesktop = false;  # or true for desktop hosts
  isAmdGpu = false;   # or true for AMD GPU systems
  users = [{
    name = "username";
    email = "user@example.com";
    fullName = "Full Name";
  }];
};
```

### Disk Configuration (Disko)

The current host uses LUKS encryption on btrfs with these subvolumes:
- `/root` → `/`
- `/home` → `/home`
- `/nix` → `/nix`
- `/swap` → `/.swap` (16GB swapfile)

All subvolumes use `compress=zstd` and `noatime` mount options. Disko configuration is in `hosts/${hostname}/disko.nix`.

### Secret Management

Secrets are managed with SOPS and age encryption:
- System secrets: defined in host `configuration.nix` (e.g., WireGuard keys)
- User secrets: defined in `users/user.nix` (API keys, container registry credentials)
- Age keys derived from SSH host keys (`ssh-to-age`)
- Secrets file: `secrets/default.yml`
- SOPS configuration: `.sops.yaml`

To edit secrets:
```sh
sops secrets/default.yml
```

### User Management via Custom Options

Users are declared in host configuration using the custom `my.users.users.<name>` options:
```nix
my.users.users.ketan = {
  name = "ketan";
  fullName = "Ketan Vijayvargiya";
  email = "hi@ketanvijayvargiya.com";
  hashedPassword = "$y$...";
  isAdmin = true;
  sshKeys = [ "ssh-ed25519 ..." ];
  extraGroups = [ "docker" "networkmanager" "podman" ];
};
```

The `modules/users.nix` module processes these options to create system users and applies the corresponding user template from `users/user.nix` via home-manager.

## Testing Changes

When modifying configurations:
1. Make changes to relevant .nix files
2. Test with `sudo nixos-rebuild test --flake .#yakima` (doesn't add to boot menu)
3. If successful, apply with `sudo nixos-rebuild switch --flake .#yakima`
4. Commit changes to git

For module changes, ensure the module option is enabled in the host configuration.

## Additional instructions

- Never add trivial code comments. ONLY add when the business logic is complex enough to warrant comments.
