{ lib, ... }:
let

  disks_rpool_vanif0 = [
    "nvme-CT1000P2SSD8_2143E5DDD965"
    "nvme-CT1000P2SSD8_2143E5DDDAD0"
    "nvme-CT1000P2SSD8_2143E5DDDAD3"
    "nvme-CT1000P2SSD8_2143E5DE3940"
    "nvme-CT1000P2SSD8_2143E5DE3947"
    "nvme-CT1000P2SSD8_2143E5DE3994"
  ];

  INST_PARTSIZE_ESP = 2; # in GB
  INST_PARTSIZE_SWAP = 36;
  INST_PARTSIZE_RPOOL = 0;

  #Number  Start   End     Size    File system  Name  Flags
  # 1      1049kB  2149MB  2147MB  fat32              boot, esp
  # 4      2149MB  36.5GB  34.4GB                     swap
  # 3      36.5GB  1000GB  964GB

  define_disk = n: disks:
    let
      disk = lib.elemAt disks n;
      id = if n == 0 then "" else toString (n + 1);
    in
    {
      name = disk;
      value = {
        device = "/dev/disk/by-id/${disk}";
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              # ESP
              index = 1;
              type = "partition";
              name = "EFI system partition"; #-t1:EF00
              fs-type = "fat32";
              start = "1M";
              end = "${toString INST_PARTSIZE_ESP}GiB";
              flags = [ "boot" "esp" ];
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi${id}";
                mountOptions = [
                  "x-systemd.idle-timeout=1min"
                  "x-systemd.automount"
                  "noauto"
                  "X-mount.mkdir"
                ];
              };
            }
            {
              # SWAP
              index = 4;
              type = "partition";
              name = "swap"; #-t4:8200
              fs-type = "linux-swap";
              start = "${toString INST_PARTSIZE_ESP}GiB";
              end = "${toString (INST_PARTSIZE_ESP+INST_PARTSIZE_SWAP)}GiB";
              flags = [ "swap" ];
              content = {
                type = "swap";
                randomEncryption = true;
              };
            }
            {
              # RPOOL
              index = 3;
              type = "partition";
              name = "zfs"; #-t3:BF00
              start = "${toString (INST_PARTSIZE_ESP+INST_PARTSIZE_SWAP)}GiB";
              end = "100%";
              content = {
                type = "zfs";
                pool = "rpool_vanif0";
              };
            }
          ];
        };
      };
    };

  ds_mount = mountpoint: {
    zfs_type = "filesystem";
    inherit mountpoint;
    options.mountpoint = "legacy";
    mountOptions = [
      "X-mount.mkdir"
    ];
  };

in
{
  disk = (lib.listToAttrs (lib.genList (n: define_disk n disks_rpool_vanif0) (lib.length disks_rpool_vanif0))) // {
    # checkout the example folder for how to configure different disko layouts
    ata-ST4000DM004-2CV104_ZTT5JV3S = {
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
  };
  nodev = {
    "/tmp" = {
      fsType = "tmpfs";
      mountOptions = [
        "defaults"
        "noatime"
        "mode=1777"
        "size=140G"
      ];
    };
  };
  zpool = {
    rpool_vanif0 = {
      type = "zpool";
      mode = "raidz2";
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
        "local/root" = ds_mount "/";
        "local/nix" = ds_mount "/nix";
        "safe/home/root" = ds_mount "/root";
        "safe/home/dguibert" = ds_mount "/home/dguibert";
        "safe/home/dguibert/Videos" = ds_mount "/home/dguibert/Videos";
        "safe/home/dguibert/notmuch" = ds_mount "/home/dguibert/Maildir/.notmuch";
        "safe/persist" = ds_mount "/persist";

        "local/nix--home_nfs-bguibertd-nix" = ds_mount "/home_nfs/bguibertd/nix";
        "local/nix--home_nfs_robin_ib-bguibertd-nix" = ds_mount "/home_nfs_robin_ib/bguibertd/nix";
        "local/nix--p-project-prcoe08-guibert1-nix" = ds_mount "/p/project/prcoe08/guibert1/nix";
        "local/nix--cluster-projects-nn9560k-dguibert" = ds_mount "/cluster/projects/nn9560k/dguibert";
        "local/nix--scratch-work-guibertd-nix" = ds_mount "/scratch/work/guibertd/nix";
        "local/nix--home-b-b381115-nix" = ds_mount "/home/b/b381115/nix";
        "local/nix--users-dguibert-nix" = ds_mount "/users/dguibert/nix";
      };
    };
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
          mountOptions = [
            "defaults"
            "x-systemd.automount"
            "noauto"
          ];
        };
      };
    };
  };
}
