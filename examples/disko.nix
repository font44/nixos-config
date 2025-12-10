{
  disko.devices = {
    disk = {
      data1 = {
        type = "disk";
        device = "/dev/vdb";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "btrfs";
                subvolumes = {
                  "/files" = {
                    mountOptions = [ "compress=zstd" ];
                    mountpoint = "/files";
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
