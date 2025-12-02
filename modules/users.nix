{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.users;

  userModule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Username";
      };

      fullName = mkOption {
        type = types.str;
        description = "Full name of the user";
      };

      email = mkOption {
        type = types.str;
        description = "Email address";
      };

      hashedPassword = mkOption {
        type = types.str;
        description = "Hashed password (generate with mkpasswd)";
      };

      isAdmin = mkOption {
        type = types.bool;
        default = false;
        description = "Whether user is an administrator";
      };

      sshKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "SSH public keys for the user";
      };

      shell = mkOption {
        type = types.package;
        default = pkgs.zsh;
        description = "Default shell for the user";
      };

      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional groups for the user";
      };
    };
  };
in {
  options.my.users = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable user management";
    };

    mutableUsers = mkOption {
      type = types.bool;
      default = false;
      description = "Allow users to be managed outside of configuration";
    };

    wheelNeedsPassword = mkOption {
      type = types.bool;
      default = false;
      description = "Require password for sudo";
    };

    users = mkOption {
      type = types.attrsOf userModule;
      default = {};
      description = "User configurations";
    };
  };

  config = mkIf cfg.enable {
    users.mutableUsers = cfg.mutableUsers;
    security.sudo.wheelNeedsPassword = cfg.wheelNeedsPassword;

    users.users = mapAttrs (name: user: {
      isNormalUser = true;
      description = user.fullName;
      hashedPassword = user.hashedPassword;
      shell = user.shell;
      extraGroups = user.extraGroups ++ (if user.isAdmin then [ "wheel" ] else []);
      openssh.authorizedKeys.keys = user.sshKeys;
    }) cfg.users;

    programs.zsh.enable = true;
  };
}
