# Shared home-manager configuration applied to all users system-wide.
# Uses sharedModules to provide common tools.
# Contrast with users/user.nix which contains per-user settings.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.home;
in {
  options.my.home = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable home-manager shared configuration (shell, editor, terminal)";
    };
  };

  config = mkIf cfg.enable {
    home-manager.sharedModules = [{
      programs.zsh = {
        enable = true;
        syntaxHighlighting.enable = true;
      };

      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };

      programs.tmux = {
        enable = true;
        mouse = true;
        historyLimit = 10000;
      };

      programs.zellij = {
        enable = true;
      };
    }];
  };
}
