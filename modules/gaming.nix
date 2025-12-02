{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.desktop.gaming;
in {
  options.my.desktop.gaming = {
    enable = mkEnableOption "gaming support (Steam, Lutris, etc.)";
  };

  config = mkIf cfg.enable {
    programs.steam.enable = true;
    programs.gamemode.enable = true;

    environment.systemPackages = with pkgs; [
      lutris
      mangohud
      protonup-qt
    ];
  };
}
