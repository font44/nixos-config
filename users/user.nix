{ name, email, fullName, ... }@userParams:

{ config, lib, pkgs, inputs, ... }:

{
  home.username = name;
  home.homeDirectory = lib.mkDefault "/home/${name}";

  programs.git = {
    enable = true;
    userName = fullName;
    userEmail = email;
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
    DEV_API_KEY_FOR_OPEN_ROUTER = "$(cat ${config.sops.secrets."api_key/open_router".path})";
    DEV_API_KEY_FOR_TAVILY = "$(cat ${config.sops.secrets."api_key/tavily".path})";
    GITLAB_REGISTRY_USERNAME = "$(cat ${config.sops.secrets."container_registry/gitlab/username".path})";
    GITLAB_REGISTRY_TOKEN = "$(cat ${config.sops.secrets."container_registry/gitlab/token".path})";
  };

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets/default.yml;
    secrets = {
      "api_key/open_router" = {};
      "api_key/tavily" = {};
      "container_registry/gitlab/username" = {};
      "container_registry/gitlab/token" = {};
    };
  };

  home.file = {
    ".step/certs/root_ca.crt".source = ../stepca/root_ca.crt;
    ".step/config/defaults.json".source = ../stepca/config.json;
  };

  home.stateVersion = "25.05";
}
