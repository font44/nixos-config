# nix-config

Command to install NixOS for the first time using Disko:

```sh
sudo nix run --experimental-features 'nix-command flakes' 'github:nix-community/disko/latest#disko-install' -- --flake .#yakima --disk main /dev/nvme0n1

# Use the following to deal with new disks. However, disko probably doesn't support running stuff remotely, so you need to copy the config file to remote
# host and run the following there. See example file in the 'examples' directory.
# Additionally, you can do: `--mode destroy,format,mount`
sudo nix run github:nix-community/disko/latest -- /tmp/disk-config.nix --mode format,mount
```
