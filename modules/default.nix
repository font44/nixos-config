{ ... }:

{
  imports = [
    ./nix.nix
    ./networking.nix
    ./users.nix
    ./desktop.nix
    ./gaming.nix
    ./local-llm.nix
    ./dev-setup.nix
    ./home.nix
    ./home-desktop.nix
  ];
}
