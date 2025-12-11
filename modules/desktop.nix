{ config, inputs, lib, pkgs, pkgs-unstable, ... }:

with lib;

let
  cfg = config.my.desktop;
in {
  options.my.desktop = {
    enable = mkEnableOption "desktop environment (Plasma, audio, printing)";
  };

  config = mkIf cfg.enable {
    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm.enable = true;

    programs.partition-manager.enable = true;
    programs.localsend.enable = true;

    nixpkgs.config.permittedInsecurePackages = [ "ventoy-qt5-1.1.05" ];
    environment.systemPackages = with pkgs; [
      bitwarden-desktop
      libreoffice
      signal-desktop
      ventoy-full-qt
      vlc
      vscode
      zoom-us
    ] ++ (with pkgs-unstable; [
      obsidian
    ]) ++ [
      inputs.deploy-rs.packages.${pkgs.system}.deploy-rs
    ];

    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    security.rtkit.enable = true;

    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
