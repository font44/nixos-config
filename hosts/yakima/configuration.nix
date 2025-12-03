{ config, inputs, pkgs, pkgs-unstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  time.timeZone = "America/Los_Angeles";

  my.networking.enable = true;
  my.desktop.gaming.enable = true;
  my.dev-setup.enable = true;

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

  sops.defaultSopsFile = ../../secrets/default.yml;
  sops.secrets = {
    "wireguard/wg0/my_private_key" = {};
    "wireguard/wg0/peer_psk" = {};
  };

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

  system.stateVersion = "25.05";
}
