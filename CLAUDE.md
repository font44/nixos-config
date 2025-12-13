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

### Backup Management
```sh
# Check backup status and timers
systemctl status restic-backups-home.service
systemctl list-timers restic-backups-home.timer

# Trigger manual backup
sudo systemctl start restic-backups-home.service

# Monitor backup execution
sudo journalctl -fu restic-backups-home.service

# List snapshots
sudo restic -r /mnt/nfs-backups/yakima-restic-repo snapshots \
  --password-file /run/secrets/backups/restic/password

# Restore files from latest snapshot
sudo restic -r /mnt/nfs-backups/yakima-restic-repo restore latest \
  --target /tmp/restore --password-file /run/secrets/backups/restic/password
```

### Deployment Workflows

#### Local Deployment (nixos-rebuild)
Traditional workflow for local development and testing:
```sh
# Local rebuild
sudo nixos-rebuild switch --flake .#yakima

# Remote rebuild
nixos-rebuild switch --flake .#chicago \
  --target-host ketan@chicago --use-remote-sudo
```

#### Automated Deployment (deploy-rs)
Recommended for production deployments with rollback safety:
```sh
# Deploy single host
deploy .#yakima
deploy .#chicago

# Deploy all hosts
deploy

# Validate configuration before deploying
nix flake check

# Dry run (preview without activating)
deploy --dry-activate .#chicago
```

**When to use which:**
- **deploy-rs**: Production (automatic rollback, validation, parallel deploys)
- **nixos-rebuild**: Local testing and development

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
  - Passes `pkgs-unstable`, `users`, and other args via specialArgs
  - Imports all modules from `modules/`
  - Loads host-specific configuration from `hosts/${hostname}/`
  - Conditionally enables modules based on boolean flags
  - Sets up home-manager foundation (users configured in `modules/users.nix`)

**Modules Layer (modules/)**
- Each module uses the `my.${module-name}.enable` option pattern
- `modules/default.nix`: Imports all available modules
- Individual modules define `options.my.${name}` for configuration
- All modules use `mkIf cfg.enable` for conditional activation
- Available modules: base, nix, networking, users, desktop (KDE), gaming, local-llm (Ollama), dev-setup, home, home-desktop, amd-gpu, restic-backup

**Host Layer (hosts/${hostname}/)**
- `configuration.nix`: Host-specific settings (timezone, services, system configuration)
- `hardware-configuration.nix`: Auto-generated hardware configuration
- `disko.nix`: Optional disk partitioning schema (LUKS + btrfs)

**User Layer (users/)**
- `user.nix`: Reusable user configuration template
- Takes parameters: name, email, fullName
- Defines home-manager configuration with git, sops secrets, session variables
- Applied to users via home-manager in `modules/users.nix`

### Special Args Pattern

`mkSystem.nix` creates and passes these special arguments to all modules:
```nix
specialArgs = {
  inherit inputs pkgs-unstable hostname users;
};
```

Use `pkgs` for stable packages (25.05) and `pkgs-unstable` for newer versions. The `users` attrset is passed from `flake.nix` and contains user definitions.

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
4. Add host to `flake.nix` using `lib.mkSystem` with user definitions:
```nix
nixosConfigurations.newhostname = lib.mkSystem {
  hostname = "newhostname";
  system = "x86_64-linux";
  isDesktop = false;  # or true for desktop hosts
  isAmdGpu = false;   # or true for AMD GPU systems
  users = {
    username = {
      name = "username";
      fullName = "Full Name";
      email = "user@example.com";
      hashedPassword = "$y$...";  # generate with mkpasswd
      isAdmin = true;
      sshKeys = [ "ssh-ed25519 ..." ];
      extraGroups = [ "docker" "networkmanager" ];
    };
  };
};
```

### Building VM Bootstrap Images

```sh
nix build .#vm-bootstrap-proxmox  # Proxmox VMA format
nix build .#vm-bootstrap-qcow2    # Other providers
```

Bootstrap contains minimal server config with 'bootstrap' user for SSH access.

### Building LXC Bootstrap Images

```sh
nix build .#lxc-bootstrap-proxmox
```

Minimal LXC template with 'ketan' user, SSH access, and disabled sandbox (required for LXC). See https://nixos.wiki/wiki/Proxmox_Linux_Container

### Deploying to Proxmox

#### Deploying VMs

1. Build and upload bootstrap:
```sh
nix build .#vm-bootstrap-proxmox
scp result/vzdump-* root@10.0.1.105:/var/lib/vz/dump/
```

2. Create and start VM on Proxmox host:
```sh
qmrestore /var/lib/vz/dump/vzdump-foo 104 --unique true --storage fast-zfs-pool-crypt
qm set 104 --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0 --name chicago
qm start 104
```

3. Generate hardware config, age keys, encrypt secrets (see .sops.yaml)

4. Apply full configuration:
```sh
nixos-rebuild switch --flake .#chicago --target-host ketan@<vm-ip> --use-remote-sudo
```

#### Deploying LXCs

1. Build and upload template:
```sh
nix build .#lxc-bootstrap-proxmox
scp result/tarball/*.tar.xz root@10.0.1.105:/var/lib/vz/template/cache/
```

2. Create and start container on Proxmox host (use CLI, GUI unreliable):
```sh
pct create 200 /var/lib/vz/template/cache/nixos-*.tar.xz \
  --hostname chicago-lxc --memory 2048 --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --storage fast-zfs-pool-crypt --rootfs fast-zfs-pool-crypt:8 \
  --unprivileged 0 --features nesting=1
pct start 200
```

3. Find IP and apply configuration:
```sh
pct exec 200 -- ip addr show
nixos-rebuild switch --flake .#chicago --target-host ketan@<container-ip> --use-remote-sudo
```

### Deploying to Other Providers

For Hetzner, Digital Ocean, etc.:
```sh
nix build .#vm-bootstrap-qcow2
# Upload according to provider instructions
# Then run remote rebuild with target host configuration
nixos-rebuild switch --flake .#hostname --target-host bootstrap@<vm-ip> --use-remote-sudo
```


### Server Module

`my.server.enable` provides VM-optimized config (QEMU guest agent, auto-resize, serial console). Automatically enabled when `isServer = true` in flake.nix.

### Disk Configuration (Disko)

LUKS encryption on btrfs with subvolumes for `/`, `/home`, `/nix`, and swap. Configuration in `hosts/${hostname}/disko.nix`.

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

### User Management

Users defined in `flake.nix` as parameter to `lib.mkSystem`. The users attrset is passed through specialArgs. `modules/users.nix` creates system users and sets up home-manager integration using templates from `users/user.nix`.

Note: SSH key-based auth only. Passwords work for local/console login and sudo.

### Backup Configuration

Restic backups to NFS server (10.0.1.40) at `/mnt/nfs-backups/${hostname}-restic-repo`.
- Module: `modules/restic-backup.nix` (enabled via `my.backup.enable`)
- Schedule: Twice daily at 02:00 and 14:00
- Target: `/home` with exclusions for caches, trash, dev artifacts, package caches
- Retention: 7 daily, 4 weekly, 6 monthly, 1 yearly
- Password: SOPS encrypted at `backups/restic/password`

Override in host config:
```nix
my.backup = {
  enable = true;
  schedule = "03:00,15:00";
  paths = [ "/home" "/etc" ];
  exclude = [ "/home/*/custom-exclude" ];
};
```

## Testing Changes

When modifying configurations:
1. Make changes to relevant .nix files
2. Test with `sudo nixos-rebuild test --flake .#yakima` (doesn't add to boot menu)
3. If successful, apply with `sudo nixos-rebuild switch --flake .#yakima`
4. Commit changes to git

For module changes, ensure the module option is enabled in the host configuration.

## Additional instructions

- Never add trivial code comments. ONLY add when the business logic is complex enough to warrant comments.
