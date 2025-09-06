{ config, inputs, pkgs, pkgs-unstable, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  networking.hostName = "nixos";
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
    loadModels = [ "gpt-oss:20b" "qwen3:30b" ];
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
  services.printing.enable = true;
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
    hashedPassword = "$y$j9T$nRWH5xd2bDz3AGt4MQa2p0$GziPLTNhiS9mSCq.Me9i8hqNqTXSNkWB4NkO4r9u6x3";  # Generate using: mkpasswd
    extraGroups = [ "docker" "networkmanager" "podman" "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGnS3nk+5uL0BE4oGpUf0JBYFNjJOcqLHjtiS3MVFGhM"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.kdeconnect.enable = true;
  programs.partition-manager.enable = true;
  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    age
    bitwarden-desktop
    btop
    devenv
    dua
    fluxcd
    hugo
    jq
    kubectl
    libreoffice
    lutris
    mangohud
    ncdu
    nvtopPackages.amd
    obsidian
    openssl
    protonup-qt
    signal-desktop
    sops
    ssh-to-age
    talosctl
    tree
    vlc
    vscode
    zoom-us

  ] ++ (with pkgs-unstable; [
    obsidian
  ]) ++ (with inputs.nix-ai-tools.packages.${pkgs.system}; [
    claude-code
    crush
    gemini-cli
    qwen-code
  ]);

  virtualisation.podman = {
    enable = true;
  };

  system.stateVersion = "25.05";
}
