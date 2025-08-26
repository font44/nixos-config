{
  description = "A simple NixOS flake";

  nixConfig.extra-substituters = [
    "https://cache.flox.dev"
  ];
  nixConfig.extra-trusted-public-keys = [
    "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
  ];

  inputs = {
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flox.url = "github:flox/flox";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.yakima = nixpkgs.lib.nixosSystem {
      inherit system;
      
      specialArgs = {
        inherit inputs;

        pkgs-unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      modules = [
        ./configuration.nix
	inputs.disko.nixosModules.disko
	{
	  disko.devices = {
	    disk = {
	      main = {
		type = "disk";
		device = "/dev/disk/by-id/some-disk-id";
		content = {
		  type = "gpt";
		  partitions = {
		    ESP = {
		      size = "512M";
		      type = "EF00";
		      content = {
		        type = "filesystem";
		        format = "vfat";
		        mountpoint = "/boot";
		        mountOptions = [ "umask=0077" ];
		      };
		    };
		    luks = {
		      size = "100%";
		      content = {
		        type = "luks";
		        name = "crypted";
		        settings = {
		          allowDiscards = true;
		        };
		        content = {
		          type = "btrfs";
		          extraArgs = [ "-f" ];
		          subvolumes = {
		            "/root" = {
		              mountpoint = "/";
		              mountOptions = [
		                "compress=zstd"
		                "noatime"
		              ];
		            };
		            "/home" = {
		              mountpoint = "/home";
		              mountOptions = [
		                "compress=zstd"
		                "noatime"
		              ];
		            };
		            "/nix" = {
		              mountpoint = "/nix";
		              mountOptions = [
		                "compress=zstd"
		                "noatime"
		              ];
		            };
		            "/swap" = {
		              mountpoint = "/.swap";
		              swap.swapfile.size = "16G";
		            };
		          };
		        };
		      };
		    };
		  };
		};
	      };
	    };
	  };
	}
        inputs.flox.nixosModules.flox

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };

          home-manager.users.ketan = import ./home.nix;
        }
      ];
    };
  };
}
