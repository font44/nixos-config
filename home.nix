{ config, pkgs, ... }:

{
  home.username = "ketan";
  home.homeDirectory = "/home/ketan";

  programs.git = {
    enable = true;
    userEmail = "hi@ketanvijayvargiya.com";
    userName = "Ketan Vijayvargiya";
  };
  programs.firefox = {
    enable = true;
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
  programs.tmux = {
    enable = true;
  };
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
  };

  services.syncthing = {
    enable = true;
    overrideDevices = true;
    settings.devices = {
      "f02aa75af4c0" = {
        id = "NIULDNJ-WZLFXF6-B2CFGL3-OXC6KXH-GDRXXTH-FIRCQTE-Q6XVEFY-46GGAQS";
      };
    };
  };

  home.stateVersion = "25.05";
}
