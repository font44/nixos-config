{ config, inputs, lib, pkgs, pkgs-unstable, ... }:

with lib;

let
  cfg = config.my.dev-setup;

  my-kubernetes-helm = with pkgs; wrapHelm kubernetes-helm {
    plugins = with pkgs.kubernetes-helmPlugins; [
      helm-secrets
      helm-diff
      helm-s3
      helm-git
    ];
  };

  my-helmfile = pkgs.helmfile-wrapped.override {
    inherit (my-kubernetes-helm) pluginsDir;
  };
in {
  options.my.dev-setup = {
    enable = mkEnableOption "development setup (containers, kubernetes, dev tools)";
  };

  config = mkIf cfg.enable {
    virtualisation.podman.enable = true;

    environment.systemPackages = [
      my-kubernetes-helm
      my-helmfile
    ] ++ (with pkgs; [
      age
      ansible
      btop
      dig
      dua
      envsubst
      fluxcd
      hugo
      jq
      ncdu
      openssl
      sops
      ssh-to-age
      step-cli
      tree
    ]) ++ (with pkgs-unstable; [
      kubectl
      talosctl
    ]) ++ (with inputs.nix-ai-tools.packages.${pkgs.system}; [
      claude-code
      crush
      gemini-cli
      opencode
    ]);
  };
}
