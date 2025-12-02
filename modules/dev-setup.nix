{ config, lib, pkgs, pkgs-unstable, ... }:

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
    # Container runtime
    virtualisation.podman.enable = true;

    # Development packages
    environment.systemPackages = [
      # Kubernetes tools
      my-kubernetes-helm
      my-helmfile
      pkgs.fluxcd

      # Dev tools
      pkgs.age
      pkgs.ansible
      pkgs.ansible-lint
      pkgs.btop
      pkgs.dig
      pkgs.dua
      pkgs.envsubst
      pkgs.hugo
      pkgs.jq
      pkgs.ncdu
      pkgs.openssl
      pkgs.sops
      pkgs.ssh-to-age
      pkgs.step-cli
      pkgs.tree
    ] ++ (with pkgs-unstable; [
      kubectl
      talosctl
    ]);
  };
}
