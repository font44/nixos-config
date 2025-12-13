{ config, lib, pkgs, ... }:

{
  my.networking.enable = true;

  services = {
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };

  fileSystems."/mnt/media" = {
    device = "10.0.1.40:/var/nfs/shared/Media/library";
    fsType = "nfs";
  };

  system.stateVersion = "25.05";
}
