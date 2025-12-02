{ inputs }:

{ hostname
, system
, users
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
    inherit inputs pkgs-unstable;
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

      home-manager.users = builtins.listToAttrs (
        map (user: {
          name = user.name;
          value = import ../users/user.nix user;
        }) users
      );
    }

    (../hosts + "/${hostname}/configuration.nix")
    (../hosts + "/${hostname}/hardware-configuration.nix")
  ] ++ (
    if builtins.pathExists (../hosts + "/${hostname}/disko.nix")
    then [ (../hosts + "/${hostname}/disko.nix") ]
    else [ ]
  );
}
