{ config, lib, modulesPath, ... }:

with lib;

let
  cfg = config.my.server;
in {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  options.my.server = {
    enable = mkEnableOption "Generic server/VM configuration";

    enableQemuGuest = mkOption {
      type = types.bool;
      default = true;
      description = "Enable QEMU guest agent for better VM management";
    };

    enableAutoGrow = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic partition and filesystem growth on boot";
    };

    bootDevice = mkOption {
      type = types.str;
      default = "/dev/vda";
      description = "Boot device for GRUB (use 'nodev' for systemd-boot)";
    };

    useSystemdBoot = mkOption {
      type = types.bool;
      default = false;
      description = "Use systemd-boot instead of GRUB";
    };
  };

  config = mkIf cfg.enable {
    services.qemuGuest.enable = mkDefault cfg.enableQemuGuest;

    boot.loader = mkMerge [
      (mkIf (!cfg.useSystemdBoot) {
        grub = {
          enable = true;
          device = cfg.bootDevice;
          efiSupport = false;
        };
      })
      (mkIf cfg.useSystemdBoot {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      })
    ];

    boot.growPartition = mkIf cfg.enableAutoGrow true;
    boot.kernelParams = [ "console=tty0" "console=ttyS0,115200" ];

    fileSystems."/" = mkDefault {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    networking.useDHCP = mkDefault true;
  };
}
