{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.nix;
in {
  options.my.nix = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Nix configuration";
    };

    settings = {
      experimentalFeatures = mkOption {
        type = types.listOf types.str;
        default = [ "nix-command" "flakes" ];
        description = "Experimental Nix features to enable";
      };

      trustedUsers = mkOption {
        type = types.listOf types.str;
        default = [ "root" "@wheel" ];
        description = "Users trusted to use Nix";
      };
    };

    gc = {
      automatic = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically run garbage collection";
      };

      persistent = mkOption {
        type = types.bool;
        default = true;
        description = "Make garbage collection persistent";
      };
    };

    optimise = {
      automatic = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically optimize the Nix store";
      };

      persistent = mkOption {
        type = types.bool;
        default = true;
        description = "Make optimization persistent";
      };
    };
  };

  config = mkIf cfg.enable {
    nix.settings = {
      experimental-features = cfg.settings.experimentalFeatures;
      trusted-users = cfg.settings.trustedUsers;
    };

    nix.gc = {
      automatic = cfg.gc.automatic;
      persistent = cfg.gc.persistent;
    };

    nix.optimise = {
      automatic = cfg.optimise.automatic;
      persistent = cfg.optimise.persistent;
    };

    nixpkgs.config.allowUnfree = true;
  };
}
