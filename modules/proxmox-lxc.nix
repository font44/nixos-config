{ config, lib, modulesPath, ... }:

with lib;

let
  cfg = config.my.proxmoxLxc;
in {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  options.my.proxmoxLxc = {
    enable = mkEnableOption "Proxmox LXC container configuration";
  };

  config = mkIf cfg.enable {
    proxmoxLXC = {
      enable = true;
      privileged = true;
    };

    nix.settings.sandbox = false;
  };
}
