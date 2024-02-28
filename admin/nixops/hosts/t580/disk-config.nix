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
          type = "table";
          format = "gpt";
          partitions = [
            {
              # ESP
              name = "\"EFI system partition\""; #-t1:EF00
              #fs-type = "fat32";
              start = "2048";
              end = "534527";
              flags = [ "boot" "esp" ];
              #content = {
              #  type = "filesystem";
              #  format = "vfat";
              #  mountpoint = "/boot/efi${id}";
              #  mountOptions = [
              #    "x-systemd.idle-timeout=1min"
              #    "x-systemd.automount"
              #    "noauto"
              #    "X-mount.mkdir"
              #  ];
              #};
            }
            {
              name = "Microsoft reserved";
              #type = "0C01";
              start = "534528";
              end = "567295";
            }
            {
              name = "Basic data partition";
              #type = "0700";
              start = "567296";
              end = "242136937";
            }
            {
              name = "";
              #type = "2700";
              start = "242137088";
              end = "243337215";
            }
            {
              name = "";
              #type = "2700";
              start = "243339264";
              end = "244404223";
            }
            {
              # SWAP
              name = "swap"; #-t4:8200
              fs-type = "linux-swap";
              start = "244404224";
              end = "277958655";
              flags = [ "swap" ];
              content = {
                type = "swap";
                randomEncryption = true;
              };
            }
            {
              # RPOOL
              name = "zfs"; #-t3:BF00
              #type = "A504";
              start = "277958656";
              end = "498069503";
              content = {
                type = "zfs";
                pool = "rpool_rt580";
              };
            }
            {
              name = "Basic data partition";
              #type = "2700";
              start = "498069504";
              end = "500117503";
            }
          ];
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
