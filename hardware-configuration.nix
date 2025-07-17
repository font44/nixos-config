{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/ed6a7b77-2d57-47b9-aa55-206b82a5159f";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."luks-4593747e-ed41-472d-b0c7-35499dc224cc".device = "/dev/disk/by-uuid/4593747e-ed41-472d-b0c7-35499dc224cc";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/9A6B-2B13";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp128s20f0u3u2.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp129s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp130s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
