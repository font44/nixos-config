{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.amd-gpu-support;
in {
  options.my.amd-gpu-support = {
    enable = mkEnableOption "AMD GPU support with ROCm and monitoring";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nvtopPackages.amd ];

    hardware.graphics = {
      enable = mkDefault true;
      enable32Bit = mkDefault true;
    };

    my.services.local-llm.enable = mkDefault true;
  };
}
