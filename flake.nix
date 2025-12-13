{
  description = "Multi-host NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
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

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ai-tools.url = "github:numtide/nix-ai-tools";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

      chicago = lib.mkSystem {
        hostname = "chicago";
        system = "x86_64-linux";
        isServer = true;
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
          };
        };
      };

      boulder = lib.mkSystem {
        hostname = "boulder";
        system = "x86_64-linux";
        isProxmoxLxc = true;
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
          };
        };
      };
    };

    deploy.nodes = {
      yakima = {
        hostname = "localhost";
        profiles.system = {
          user = "root";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.yakima;
        };
      };

      chicago = {
        hostname = "10.0.1.215";
        profiles.system = {
          user = "root";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.chicago;
        };
      };

      boulder = {
        hostname = "10.0.1.238";
        profiles.system = {
          user = "root";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.boulder;
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib:
      deployLib.deployChecks self.deploy
    ) inputs.deploy-rs.lib;

    packages.x86_64-linux = {
      vm-bootstrap-proxmox = inputs.nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "proxmox";
        modules = [
          ./hosts/vm-bootstrap.nix
        ];
      };

      lxc-bootstrap-proxmox = inputs.nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "proxmox-lxc";
        modules = [
          ./hosts/lxc-bootstrap.nix
        ];
      };
    };
  };
}
