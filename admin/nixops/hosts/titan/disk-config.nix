{ lib, ... }:
{
  # checkout the example folder for how to configure different disko layouts
  disk.ata-ST4000DM004-2CV104_ZTT5JV3S = {
    device = "/dev/disk/by-id/ata-ST4000DM004-2CV104_ZTT5JV3S";
    type = "disk";
    content = {
      type = "table";
      format = "gpt";
      partitions = [
        {
          type = "partition";
          name = "zfs";
          start = "128MiB";
          end = "100%";
          content = {
            type = "zfs";
            pool = "zpoot_kdbimp";
          };
        }
      ];
    };
  };
  zpool = {
    zpoot_kdbimp = {
      type = "zpool";
      #mode = "mirror";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        acltype = "posixacl";
        canmount = "off";
        compression = "zstd";
        dnodesize = "auto";
        normalization = "formD";
        recordsize = "1M";
        relatime = "on";
        xattr = "sa";
      };

      datasets = {
        backup2 = {
          zfs_type = "filesystem";
          options.mountpoint = "none";
        };
        "backup2/videos" = {
          zfs_type = "filesystem";
          mountpoint = "/backup2/Videos";
          options.mountpoint = "legacy";
        };
      };
    };
  };
}
