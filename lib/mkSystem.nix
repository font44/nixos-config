{ inputs }:

{ hostname
, system
, users ? {}
, isDesktop ? false
, isServer ? false
, isAmdGpu ? false
}:

let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs pkgs-unstable hostname users;
  };

  modules = [
    ../modules

    inputs.disko.nixosModules.disko
    inputs.flox.nixosModules.flox
    inputs.sops-nix.nixosModules.sops

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.sharedModules = [
        inputs.sops-nix.homeManagerModules.sops
      ];
    }

    {
      my.base.enable = inputs.nixpkgs.lib.mkDefault true;
    }

    (inputs.nixpkgs.lib.mkIf isDesktop {
      my.desktop.enable = inputs.nixpkgs.lib.mkDefault true;
      my.home.desktop.enable = inputs.nixpkgs.lib.mkDefault true;
      my.users.enable = inputs.nixpkgs.lib.mkDefault true;
    })

    (inputs.nixpkgs.lib.mkIf isServer {
      my.server.enable = inputs.nixpkgs.lib.mkDefault true;
      my.users.enable = inputs.nixpkgs.lib.mkDefault true;
    })

    (inputs.nixpkgs.lib.mkIf isAmdGpu {
      my.amd-gpu-support.enable = inputs.nixpkgs.lib.mkDefault true;
    })

    (../hosts + "/${hostname}/configuration.nix")
    (../hosts + "/${hostname}/hardware-configuration.nix")
  ] ++ (
    if builtins.pathExists (../hosts + "/${hostname}/disko.nix")
    then [ (../hosts + "/${hostname}/disko.nix") ]
    else [ ]
  );
}
