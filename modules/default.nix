{ ... }:

{
  imports = [
    ./amd-gpu.nix
    ./base.nix
    ./proxmox-lxc.nix
    ./desktop.nix
    ./dev-setup.nix
    ./gaming.nix
    ./home-desktop.nix
    ./home.nix
    ./local-llm.nix
    ./networking.nix
    ./nix.nix
    ./restic-backup.nix
    ./server.nix
    ./users.nix
  ];
}
