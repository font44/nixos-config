{ config, lib, pkgs, pkgs-unstable, ... }:

with lib;

let
  cfg = config.my.services.local-llm;
in {
  options.my.services.local-llm = {
    enable = mkEnableOption "local LLM stack (Ollama + Open WebUI)";
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      openFirewall = true;
      package = pkgs-unstable.ollama;
    };

    services.open-webui = {
      enable = true;
      environment = {
        WEBUI_AUTH = "False";
      };
    };
  };
}
