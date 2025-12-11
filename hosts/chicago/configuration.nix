{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  time.timeZone = "America/Los_Angeles";

  my.networking.enable = true;
  my.dev-setup.enable = true;

  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/files    10.0.1.0/24(rw,sync)
    '';
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];

  system.stateVersion = "25.05";
}
