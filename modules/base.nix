{ config, inputs, lib, ... }:

with lib;

let
  cfg = config.my.base;
in {
  options.my.base = {
    enable = mkEnableOption "base system configuration";

    locale = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
      description = "Default system locale";
    };
  };

  config = mkIf cfg.enable {
    i18n.defaultLocale = cfg.locale;
    i18n.extraLocaleSettings = {
      LC_ADDRESS = cfg.locale;
      LC_IDENTIFICATION = cfg.locale;
      LC_MEASUREMENT = cfg.locale;
      LC_MONETARY = cfg.locale;
      LC_NAME = cfg.locale;
      LC_NUMERIC = cfg.locale;
      LC_PAPER = cfg.locale;
      LC_TELEPHONE = cfg.locale;
      LC_TIME = cfg.locale;
    };

    my.nix.enable = inputs.nixpkgs.lib.mkDefault true;
  };
}
