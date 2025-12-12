{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  proxmoxLXC.privileged = true;

  networking.hostName = "bootstrap";
  networking.networkmanager.enable = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
    sandbox = false;
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.ketan = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGnS3nk+5uL0BE4oGpUf0JBYFNjJOcqLHjtiS3MVFGhM"
    ];
  };

  environment.systemPackages = [ pkgs.ssh-to-age ];

  system.stateVersion = "25.05";
}
