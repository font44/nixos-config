{ config, lib, ... }:

with lib;

let
  cfg = config.my.nix;
in {
  options.my.nix = {
    enable = mkEnableOption "Nix configuration";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" ];
    };

    nix.gc = {
      automatic = true;
      persistent = true;
    };

    nix.optimise = {
      automatic = true;
      persistent = true;
    };

    nixpkgs.config.allowUnfree = true;
  };
}
