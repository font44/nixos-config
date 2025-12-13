{ config, lib, pkgs, modulesPath, ... }:

{
  boot.isContainer = true;

  nixpkgs.hostPlatform = "x86_64-linux";
}
