{ config, inputs, pkgs, pkgs-unstable, ... }:

let
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
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  networking.hostName = "yakima";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "ketan" ];
  };

  nix.gc = {
    automatic = true;
    persistent = true;
  };
  nix.optimise = {
    automatic = true;
    persistent = true;
  };
  nixpkgs.config.rocmSupport = true;

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.ollama = {
    enable = true;
    # See https://ollama.com/library
    host = "0.0.0.0";
    openFirewall = true;
  };
  services.open-webui = {
    enable = true;
    environment = {
      WEBUI_AUTH = "False";
    };
  };
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];
  };
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  
  users.mutableUsers = false;
  users.users.ketan = {
    isNormalUser = true;
    description = "Ketan Vijayvargiya";
    hashedPassword = "$y$j9T$k5FwsT0yGXVJwrCdo0Ew//$NlntOgydAMXMX4qLvmID9IBk8p1F4kmJx3TxUMFkIf3";  # Generate using: mkpasswd
    extraGroups = [ "docker" "networkmanager" "podman" "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGnS3nk+5uL0BE4oGpUf0JBYFNjJOcqLHjtiS3MVFGhM"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  programs = {
    gamemode.enable = true;
    localsend.enable = true;
    partition-manager.enable = true;
    steam.enable = true;
    zsh.enable = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "ventoy-qt5-1.1.05" ];
  };

  environment.systemPackages = with pkgs; [
    age
    ansible
    ansible-lint
    bitwarden-desktop
    btop
    dig
    dua
    envsubst
    fluxcd
    hugo
    jq
    libreoffice
    lutris
    mangohud
    my-kubernetes-helm
    my-helmfile
    ncdu
    nvtopPackages.amd
    openssl
    protonup-qt
    signal-desktop
    sops
    ssh-to-age
    step-cli
    tree
    ventoy-full-qt
    vlc
    vscode
    zoom-us

  ] ++ (with pkgs-unstable; [
    kubectl
    obsidian
    talosctl
  ]) ++ (with inputs.nix-ai-tools.packages.${pkgs.system}; [
    claude-code
    gemini-cli
  ]);

  virtualisation.podman = {
    enable = true;
  };

  system.stateVersion = "25.05";
}
