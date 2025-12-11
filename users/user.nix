# Reusable home-manager configuration template for individual users.
# Takes user parameters (name, email, fullName) and returns home-manager config.
# Imported by modules/users.nix for each user defined in flake.nix.

{ name, email, fullName, ... }@userParams:

{ config, lib, pkgs, inputs, ... }:

{
  home.username = name;
  home.homeDirectory = lib.mkDefault "/home/${name}";

  programs.git = {
    enable = true;
    userName = fullName;
    userEmail = email;
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
    DEV_API_KEY_FOR_OPEN_ROUTER = "$(cat ${config.sops.secrets."api_key/open_router".path})";
    DEV_API_KEY_FOR_OPENAI = "$(cat ${config.sops.secrets."api_key/openai".path})";
    DEV_API_KEY_FOR_TAVILY = "$(cat ${config.sops.secrets."api_key/tavily".path})";

    GITLAB_REGISTRY_USERNAME = "$(cat ${config.sops.secrets."container_registry/gitlab/username".path})";
    GITLAB_REGISTRY_TOKEN = "$(cat ${config.sops.secrets."container_registry/gitlab/token".path})";
  };

  sops = {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    defaultSopsFile = ../secrets/default.yml;
    secrets = {
      "api_key/open_router" = {};
      "api_key/openai" = {};
      "api_key/tavily" = {};
      "container_registry/gitlab/username" = {};
      "container_registry/gitlab/token" = {};
    };
  };

  xdg.configFile."crush/crush.json".source = ../static/crush.conf.json;
  xdg.configFile."opencode/opencode.json".source = ../static/opencode.conf.json;
  xdg.configFile."opencode/AGENTS.md".source = ../static/AGENTS.md;

  home.stateVersion = "25.05";
}
