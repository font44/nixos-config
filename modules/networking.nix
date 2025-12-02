{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.networking;
in {
  options.my.networking = {
    enable = mkEnableOption "networking configuration";

    networkManager = mkOption {
      type = types.bool;
      default = true;
      description = "Enable NetworkManager for network management";
    };

    ssh.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SSH server";
    };

    avahi.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Avahi mDNS";
    };
  };

  config = mkIf cfg.enable {
    networking.networkmanager.enable = mkIf cfg.networkManager true;

    services.openssh = mkIf cfg.ssh.enable {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    services.avahi = mkIf cfg.avahi.enable {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
