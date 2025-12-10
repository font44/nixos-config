{ config, lib, pkgs, users ? {}, ... }:

with lib;

let
  cfg = config.my.users;
in {
  options.my.users = {
    enable = mkEnableOption "user management";
    
    enableHomeManager = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable home-manager for users";
    };
  };

  config = mkIf cfg.enable {
    users.mutableUsers = false;
    security.sudo.wheelNeedsPassword = false;

    users.users = mapAttrs (name: user: {
      isNormalUser = true;
      description = user.fullName;
      hashedPassword = user.hashedPassword;
      shell = user.shell or pkgs.zsh;
      extraGroups = (user.extraGroups or []) ++ (if (user.isAdmin or false) then [ "wheel" ] else []);
      openssh.authorizedKeys.keys = user.sshKeys or [];
    }) users;

    programs.zsh.enable = true;

    home-manager.users = mkIf cfg.enableHomeManager (mapAttrs (name: user: import ../users/user.nix {
      inherit (user) name email fullName;
    }) users);
  };
}
