{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.username = "ketan";
  home.homeDirectory = "/home/ketan";

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.git = {
    enable = true;
    userEmail = "hi@ketanvijayvargiya.com";
    userName = "Ketan Vijayvargiya";
  };
  programs.firefox = {
    enable = true;
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
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
    DEV_API_KEY_FOR_OPEN_ROUTER = "$(cat ${config.sops.secrets."api_key/open_router".path})";
    DEV_API_KEY_FOR_TAVILY = "$(cat ${config.sops.secrets."api_key/tavily".path})";
  };

  services.copyq.enable = true;
  services.syncthing = {
    enable = true;
    overrideFolders = false;
    settings.devices = {
      "f02aa75af4c0" = {
        id = "NIULDNJ-WZLFXF6-B2CFGL3-OXC6KXH-GDRXXTH-FIRCQTE-Q6XVEFY-46GGAQS";
      };
    };
  };

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets/default.yml;
    secrets = {
      "api_key/open_router" = {};
      "api_key/tavily" = {};
    };
  };

  xdg.configFile."crush/crush.json".source = ./crush.conf.json;
  home.file = {
    ".step/certs/root_ca.crt".source = ./stepca/root_ca.crt;
    ".step/config/defaults.json".source = ./stepca/config.json;
  };

  home.stateVersion = "25.05";
}
