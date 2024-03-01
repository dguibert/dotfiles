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
          type = "gpt";
          partitions = {
            "EFI system partition" = {
              priority = 0;
              # ESP
              type = "EF00";
              start = "1M";
              end = "${toString INST_PARTSIZE_ESP}GiB";
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
            };
            swap = {
              priority = 1;
              type = "8200";
              start = "${toString INST_PARTSIZE_ESP}GiB";
              end = "${toString (INST_PARTSIZE_ESP+INST_PARTSIZE_SWAP)}GiB";
              content = {
                type = "swap";
                #randomEncryption = true;
              };
            };
            zfs = {
              priority = 6;
              # RPOOL
              name = "zfs"; #-t3:BF00
              start = "${toString (INST_PARTSIZE_ESP+INST_PARTSIZE_SWAP)}GiB";
              end = "100%";
              content = {
                type = "zfs";
                pool = "rpool_vanif0";
              };
            };
          };
        };
      };
    };

  ds_mount = mountpoint: {
    type = "zfs_fs";
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
        type = "gpt";
        partitions.zfs = {
          start = "128MiB";
          end = "100%";
          content = {
            type = "zfs";
            pool = "zpoot_kdbimp";
          };
        };
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
        "local/home" = ds_mount "/home";
        "local/home/dguibert" = {
          #ds_mount "/home/dguibert";
          type = "zfs_fs";
          options.mountpoint = "legacy";
        };
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
        "local/nix--scratch_na-users-bguibertd-nix" = ds_mount "/scratch_na/users/bguibertd/nix";
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
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "backup2/ria" = {
          type = "zfs_fs";
          mountpoint = "/backup2/ria";
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
