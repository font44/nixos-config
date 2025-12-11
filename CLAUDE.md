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

# Restore specific files
sudo restic -r /mnt/nfs-backups/yakima-restic-repo restore latest \
  --target /tmp/restore --include /home/user/Documents \
  --password-file /run/secrets/backups/restic/password
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

**Deploy-rs Benefits:**
- Automatic rollback if activation fails
- Magic rollback if SSH connection is lost
- Pre-deployment validation checks
- Remote builds to offload work to target host
- Deploy multiple hosts in parallel

**When to use which:**
- **deploy-rs**: Production deployments, multi-host updates, when safety is critical
- **nixos-rebuild**: Local testing, development iteration, manual control

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
- Available modules:
  - `base.nix`: Core locale configuration (always enabled by default)
  - `nix.nix`: Nix daemon and flake settings
  - `networking.nix`: Network configuration with NetworkManager and OpenSSH
  - `users.nix`: User account management receiving users from specialArgs, handles both system users and home-manager integration
  - `desktop.nix`: KDE Plasma desktop environment
  - `gaming.nix`: Gaming-related packages and configurations
  - `local-llm.nix`: Ollama and Open WebUI services
  - `dev-setup.nix`: Development tools and environments
  - `home.nix`: Base home-manager configurations
  - `home-desktop.nix`: Desktop-specific home-manager settings
  - `amd-gpu.nix`: AMD GPU support
  - `restic-backup.nix`: Automated encrypted backups to NFS server

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

Build a minimal bootstrap image (once, reusable for all VMs):

```sh
# Proxmox VMA format
nix build .#vm-bootstrap-proxmox
```

The bootstrap image contains:
- Minimal server configuration (QEMU guest, auto-grow, serial console)
- Single 'bootstrap' user with SSH key
- Passwordless sudo enabled
- Just enough to SSH in and run remote rebuild

### Deploying to Proxmox

1. **Build and upload the bootstrap image** (one-time):
```sh
nix build .#vm-bootstrap-proxmox
scp result/vzdump-* root@10.0.1.105:/var/lib/vz/dump/
```

2. **Create VM from bootstrap image**:
```sh
# On Proxmox host
qmrestore /var/lib/vz/dump/vzdump-foo 104 --unique true --storage fast-zfs-pool-crypt
qm set 104 --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0 --name chicago
qm start 104

# Wait for VM to boot, then check IP
qm guest exec 100 -- ip addr show
```

3. **On the host**:
```sh
# Update hardware-configuration.nix
nixos-generate-config --show-hardware-config

# User key:
ssh-keygen -t ed25519 -C "ketan@chicago"
cat .ssh/id_ed25519.pub | ssh-to-age
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
```

4. **Encrypt secrets for the new VM**. Follow instructions in *.sops.yaml* file.

5. **Apply full configuration**:
```sh
# From your development machine
nixos-rebuild switch --flake .#chicago \
  --target-host ketan@<vm-ip> --use-remote-sudo
```

This transforms the minimal bootstrap into the full chicago configuration with all modules, users, packages, and settings.

6. **SSH with real user** (bootstrap user will be removed):
```sh
ssh ketan@<vm-ip>
```

### Deploying to Other Providers

For Hetzner, Digital Ocean, etc.:
```sh
nix build .#vm-bootstrap-qcow2
# Upload according to provider instructions
# Then run remote rebuild with target host configuration
nixos-rebuild switch --flake .#hostname --target-host bootstrap@<vm-ip> --use-remote-sudo
```

### Two-Stage Deployment Benefits

1. **Build once, use many times**: Same bootstrap image for all VMs
2. **Faster iterations**: Modify host config and just run remote rebuild
3. **Smaller images**: Bootstrap is minimal (~500MB), full packages installed on rebuild
4. **Standard workflow**: Same rebuild process for initial setup and updates

### Server Module

The `my.server.enable` module provides VM-optimized configuration:
- QEMU guest agent for provider integration
- Automatic partition resizing on first boot
- Serial console support
- Configurable boot loader (GRUB or systemd-boot)
- Works with any VM provider (Proxmox, Hetzner, Digital Ocean, etc.)

Automatically enabled when `isServer = true` in flake.nix.

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

### User Management

Users are defined in `flake.nix` as a parameter to `lib.mkSystem`:
```nix
nixosConfigurations.yakima = lib.mkSystem {
  hostname = "yakima";
  users = {
    ketan = {
      name = "ketan";
      fullName = "Ketan Vijayvargiya";
      email = "hi@ketanvijayvargiya.com";
      hashedPassword = "$y$...";
      isAdmin = true;
      sshKeys = [ "ssh-ed25519 ..." ];
      extraGroups = [ "docker" "networkmanager" "podman" ];
    };
  };
};
```

The users attrset is passed through specialArgs to all modules. The `modules/users.nix` module:
- Creates system users with the provided configuration
- Sets up home-manager integration using templates from `users/user.nix`
- Handles both system-level user accounts and home-manager configurations in one place

Note: OpenSSH is configured with `PasswordAuthentication = false` (key-based auth only). User passwords work for local/console login and sudo.

### Backup Configuration

Automated backups are configured using Restic with the following setup:

**Configuration**
- **Module**: `modules/restic-backup.nix` (enabled via `my.backup.enable`)
- **NFS Server**: 10.0.1.40 at `/var/nfs/shared/Backups`
- **Mount Point**: `/mnt/nfs-backups` (auto-mounted on access)
- **Repository**: `/mnt/nfs-backups/${hostname}-restic-repo`
- **Schedule**: Twice daily at 02:00 and 14:00
- **Backup Target**: All of `/home` with smart exclusions

**Retention Policy**
- Daily: 7 snapshots
- Weekly: 4 snapshots
- Monthly: 6 snapshots
- Yearly: 1 snapshot

**Exclusions**
Smart exclusions minimize backup size while preserving important data:
- Cache directories (`.cache`, browser caches)
- Trash folders (`.local/share/Trash`)
- Development artifacts (`node_modules`, `.venv`, `__pycache__`)
- Package caches (`.npm`, `.cargo/registry`, `.rustup`)
- Large temporary files (`*.iso`, `*.img` in Downloads)
- Regenerable data (thumbnails, file indexes)

**Security**
- Repository password stored encrypted in SOPS at `backups/restic/password`
- Restic provides client-side encryption of all backup data
- Repository directory permissions set to 700 (root-only)
- NFS mount uses `nofail` option to prevent boot failures

**Customization**
Override default backup settings in host configuration:
```nix
my.backup = {
  enable = true;
  schedule = "03:00,15:00";  # Different times
  paths = [ "/home" "/etc" ];  # Additional paths
  exclude = [ "/home/*/custom-exclude" ];  # Custom exclusions
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
