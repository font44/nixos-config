{ config, lib, pkgs, hostname, ... }:

with lib;

let
  cfg = config.my.backup;
  nfsServer = "10.0.1.40";
  nfsShare = "/var/nfs/shared/Backups";
  mountPoint = "/mnt/nfs-backups";
  repoPath = "${mountPoint}/${hostname}-restic-repo";
in {
  options.my.backup = {
    enable = mkEnableOption "automated Restic backups to NFS server";

    paths = mkOption {
      type = types.listOf types.str;
      default = [ "/home" ];
      description = "Directories to back up";
    };

    exclude = mkOption {
      type = types.listOf types.str;
      default = [
        "**/.cache"
        "**/.mozilla/*/Cache*"
        "**/.local/share/Trash"
        "**/node_modules"
        "**/.venv"
        "**/__pycache__"
        "**/.npm"
        "**/.cargo/registry"
        "**/.rustup"
        "**/Downloads/*.iso"
        "**/Downloads/*.img"
        "**/.thumbnails"
        "**/.local/share/baloo"
      ];
      description = "Patterns to exclude from backup";
    };

    pruneOpts = mkOption {
      type = types.listOf types.str;
      default = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 1"
      ];
      description = "Restic prune options for retention policy";
    };
  };

  config = mkIf cfg.enable {
    fileSystems."${mountPoint}" = {
      device = "${nfsServer}:${nfsShare}";
      fsType = "nfs";
      options = [
        "x-systemd.automount"
        "nofail"
      ];
    };

    sops.secrets."backups/restic/password" = {
      mode = "0400";
      owner = "root";
      group = "root";
    };

    services.restic.backups.home = {
      initialize = true;
      repository = repoPath;
      passwordFile = config.sops.secrets."backups/restic/password".path;

      paths = cfg.paths;
      exclude = cfg.exclude;

      pruneOpts = cfg.pruneOpts;

      backupPrepareCommand = ''
        if ! mountpoint -q ${mountPoint}; then
          echo "Error: NFS mount ${mountPoint} is not available"
          exit 1
        fi
      '';
    };

    systemd.services.restic-backups-home = {
      # systemd mount unit name: /mnt/nfs-backups → mnt-nfs\x2dbackups.mount
      # hyphens in path must be escaped as \x2d in systemd unit names
      after = [ "network-online.target" "mnt-nfs\\x2dbackups.mount" ];
      requires = [ "mnt-nfs\\x2dbackups.mount" ];
      wants = [ "network-online.target" ];
    };
  };
}
