{ config, pkgs, ... }:

{
  home.username = "ketan";
  home.homeDirectory = "/home/ketan";

  programs.git = {
    enable = true;
    userEmail = "hi@ketanvijayvargiya.com";
    userName = "Ketan Vijayvargiya";
  };

  home.packages = with pkgs; [
    neovim
  ];

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
  };

  home.stateVersion = "25.05";
}
