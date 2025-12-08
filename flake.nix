{
  description = "Multi-host NixOS configuration";

  nixConfig.extra-substituters = [
    "https://cache.flox.dev"
  ];
  nixConfig.extra-trusted-public-keys = [
    "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
  ];

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flox.url = "github:flox/flox";
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    lib = import ./lib { inherit inputs; };
  in {
    nixosConfigurations = {
      yakima = lib.mkSystem {
        hostname = "yakima";
        system = "x86_64-linux";
        isDesktop = true;
        isAmdGpu = true;
        users = {
          ketan = {
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
        };
      };
    };
  };
}
