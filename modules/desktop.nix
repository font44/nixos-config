{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.desktop;
in {
  options.my.desktop = {
    enable = mkEnableOption "desktop environment (Plasma, audio, printing)";
  };

  config = mkIf cfg.enable {
    # KDE Plasma 6
    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm.enable = true;

    programs.partition-manager.enable = true;

    # Audio (PipeWire)
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    security.rtkit.enable = true;

    # Printing (CUPS)
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };

    # Graphics
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
