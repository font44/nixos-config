{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../modules/server.nix
  ];

  my.server.enable = true;

  services.openssh.enable = true;
  security.sudo.wheelNeedsPassword = false;

  users.users.bootstrap = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGnS3nk+5uL0BE4oGpUf0JBYFNjJOcqLHjtiS3MVFGhM"
    ];
  };

  system.stateVersion = "25.05";
}
