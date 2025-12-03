{ config, lib, pkgs, hostname, ... }:

with lib;

let
  cfg = config.my.networking;
in {
  options.my.networking = {
    enable = mkEnableOption "networking configuration";
  };

  config = mkIf cfg.enable {
    networking.hostName = hostname;
    networking.networkmanager.enable = true;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
