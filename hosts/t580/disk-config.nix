{ lib, ... }:
let

  disks_rpool_rt580 = [
    "nvme-INTEL_SSDPEKKF256G8L_BTHP93731V6V256B"
  ];

  INST_PARTSIZE_ESP = 2; # in GB
  INST_PARTSIZE_SWAP = 36;
  INST_PARTSIZE_RPOOL = 0;

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
              label = "boot";
              device = "/dev/disk/by-id/${disk}-part1";
              # ESP
              type = "EF00";
              start = "2048";
              end = "534527";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "x-systemd.idle-timeout=1min"
                  "x-systemd.automount"
                  "noauto"
                  "X-mount.mkdir"
                ];
              };
            };
            "Microsoft reserved" = {
              priority = 1;
              type = "0C01";
              start = "534528";
              end = "567295";
            };
            "Basic data partition" = {
              priority = 2;
              type = "0700";
              start = "567296";
              end = "242136937";
            };
            hidden1 = {
              priority = 3;
              type = "2700";
              start = "242137088";
              end = "243337215";
            };
            hidden2 = {
              priority = 4;
              type = "2700";
              start = "243339264";
              end = "244404223";
            };
            swap = {
              label = "nvme-swap";
              device = "/dev/disk/by-id/${disk}-part6";
              priority = 5;
              type = "8200";
              start = "244404224";
              end = "277958655";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            zfs = {
              priority = 6;
              # RPOOL
              type = "A504";
              start = "277958656";
              end = "498069503";
              content = {
                type = "zfs";
                pool = "rpool_rt580";
              };
            };
            "Basic data partition2" = {
              priority = 7;
              type = "2700";
              start = "498069504";
              end = "500117503";
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
  disk = (lib.listToAttrs (lib.genList (n: define_disk n disks_rpool_rt580) (lib.length disks_rpool_rt580)));

  zpool = {
    rpool_rt580 = {
      type = "zpool";
      #mode = "raidz2";
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
      postCreateHook = "zfs snapshot local/root@blank";

      datasets = {
        "local/root" = ds_mount "/";
        "local/home" = ds_mount "/home";
        "local/nix" = ds_mount "/nix";
        "safe/home/dguibert" = ds_mount "/home/dguibert";
        "safe/home/root" = ds_mount "/root";
        "safe/persist" = ds_mount "/persist";
      };
    };
  };
}
