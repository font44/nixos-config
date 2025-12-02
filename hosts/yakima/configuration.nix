{ config, inputs, pkgs, pkgs-unstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  # Hostname and timezone
  networking.hostName = "yakima";
  time.timeZone = "America/Los_Angeles";

  # Locale settings
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

  # Enable module groups
  my.networking.enable = true;
  my.desktop.enable = true;
  my.desktop.gaming.enable = true;
  my.dev-setup.enable = true;
  my.services.local-llm.enable = true;
  my.home.desktop.enable = true;

  # User configuration
  my.users.users.ketan = {
    name = "ketan";
    fullName = "Ketan Vijayvargiya";
    email = "hi@ketanvijayvargiya.com";
    hashedPassword = "$y$j9T$k5FwsT0yGXVJwrCdo0Ew//$NlntOgydAMXMX4qLvmID9IBk8p1F4kmJx3TxUMFkIf3";
    isAdmin = true;
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGnS3nk+5uL0BE4oGpUf0JBYFNjJOcqLHjtiS3MVFGhM"
    ];
    extraGroups = [ "docker" "networkmanager" "podman" ];
  };

  # SOPS secrets
  sops.defaultSopsFile = ../../secrets/default.yml;
  sops.secrets = {
    "wireguard/wg0/my_private_key" = {};
    "wireguard/wg0/peer_psk" = {};
  };

  # WireGuard (host-specific configuration)
  networking.wg-quick.interfaces = {
    wg0 = {
      address = [
        "10.132.76.14/32"
        "fd7d:76ee:e68f:a993:7a5a:2d9b:d8e8:9f81/128"
      ];
      dns = [
        "10.128.0.1"
        "fd7d:76ee:e68f:a993::1"
      ];
      mtu = 1320;
      privateKeyFile = config.sops.secrets."wireguard/wg0/my_private_key".path;
      autostart = false;
      peers = [
        {
          publicKey = "PyLCXAQT8KkM4T+dUsOQfn+Ub3pGxfGlxkIApuig+hk=";
          presharedKeyFile = config.sops.secrets."wireguard/wg0/peer_psk".path;
          endpoint = "us3.vpn.airdns.org:1637";
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
        }
      ];
    };
  };

  # Additional programs
  programs.localsend.enable = true;

  # Additional packages not in modules
  nixpkgs.config.permittedInsecurePackages = [ "ventoy-qt5-1.1.05" ];
  environment.systemPackages = with pkgs; [
    bitwarden-desktop
    libreoffice
    nvtopPackages.amd
    signal-desktop
    ventoy-full-qt
    vlc
    vscode
    zoom-us
  ] ++ (with pkgs-unstable; [
    obsidian
  ]) ++ (with inputs.nix-ai-tools.packages.${pkgs.system}; [
    claude-code
  ]);

  # ROCm support for AMD GPU
  nixpkgs.config.rocmSupport = true;

  system.stateVersion = "25.05";
}
