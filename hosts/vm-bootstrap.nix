{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../modules/server.nix
  ];

  my.server.enable = true;

  networking.hostName = "bootstrap";
  networking.networkmanager.enable = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
  };

  services.openssh.enable = true;
  security.sudo.wheelNeedsPassword = false;

  users.users.ketan = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGnS3nk+5uL0BE4oGpUf0JBYFNjJOcqLHjtiS3MVFGhM"
    ];
  };

  virtualisation.diskSize = 32768;
  environment.systemPackages = [ pkgs.ssh-to-age ];

  system.stateVersion = "25.05";
}
