{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  time.timeZone = "America/Los_Angeles";

  my.networking.enable = true;
  my.dev-setup.enable = true;

  system.stateVersion = "25.05";
}
