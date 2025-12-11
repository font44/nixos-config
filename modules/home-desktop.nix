# Shared home-manager configuration for desktop-specific programs.
# Uses sharedModules to provide GUI applications for all users on desktop hosts.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.home.desktop;
in {
  options.my.home.desktop = {
    enable = mkEnableOption "desktop-specific home-manager programs (firefox, copyq, syncthing)";
  };

  config = mkIf cfg.enable {
    home-manager.sharedModules = [{
      programs.firefox.enable = true;

      services.copyq.enable = true;

      services.syncthing = {
        enable = true;
        overrideFolders = false;
        settings.devices = {
          "f02aa75af4c0" = {
            id = "NIULDNJ-WZLFXF6-B2CFGL3-OXC6KXH-GDRXXTH-FIRCQTE-Q6XVEFY-46GGAQS";
          };
        };
      };
    }];
  };
}
