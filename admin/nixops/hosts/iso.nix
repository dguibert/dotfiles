{ config, pkgs, lib, ... }:
let
  inherit (lib) concatMapStrings concatMapStringsSep head;
  disks_st1000lm049 = [
    "/dev/disk/by-id/ata-ST1000LM049-2GH172_WGS20WGY"
    #"/dev/disk/by-id/ata-ST1000LM049-2GH172_WGS20WJB" #20190726
    "/dev/disk/by-id/ata-ST1000LM049-2GH172_WGS20WK1"
    #"/dev/disk/by-id/ata-ST1000LM049-2GH172_WGS25WVG"
    "/dev/disk/by-id/ata-ST1000LM049-2GH172_WGS1T415"
    "/dev/disk/by-id/ata-ST1000LM049-2GH172_WGS25XFD"
    #"/dev/disk/by-id/ata-ST1000LM049-2GH172_WGS25Z1Y" # 20190726
    "/dev/disk/by-id/ata-ST1000LM048-2E7172_WQ90DBRQ"
  ];
  disks = [
    "/dev/disk/by-id/ata-ST3160812AS_5LS8DN8Z"
    "/dev/disk/by-id/ata-ST3160815AS_5RX02WNE"
  ];
  ## https://github.com/zfsonlinux/zfs/wiki/Ubuntu-18.04-Root-on-ZFS
  format_disk = disk: ''
    dd if=/dev/zero of=${disk} bs=512 count=10000
    sgdisk -o ${disk} || true
    sgdisk -o ${disk} || true
    sgdisk -o ${disk} || true
    # Run this if you need legacy (BIOS) booting:
    #  sgdisk -a1 -n2:34:2047  -t2:EF02 ${disk}
    # Run this for UEFI booting (for use now or in the future):
    sgdisk     -n3:1M:+512M -t3:EF00 ${disk}
    #  # Unencrypted:
    sgdisk     -n1:0:0      -t1:BF01 ${disk}

    # LUKS:
    # sgdisk     -n4:0:+512M  -t4:8300 ${disk}
    # sgdisk     -n1:0:0      -t1:8300 ${disk}
  '';

  zfs_create_mirror_pool = pool_name: disks: zfs_create_pool pool_name "mirror" disks;
  zfs_create_raidz2_pool = pool_name: disks: zfs_create_pool pool_name "raidz2" disks;

  zfs_create_pool = pool_name: type: disks: ''
    # Unencrypted:
    zpool create -o ashift=12 \
          -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
          -O xattr=sa -O mountpoint=/ -R /mnt \
          -f \
          ${pool_name} ${type} ${concatMapStringsSep " " (x: "${x}-part1") disks}
    # LUKS:
    # cryptsetup luksFormat -c aes-xts-plain64 -s 256 -h sha256 $disk-part1
    # cryptsetup luksOpen $disk-part1 luks1
    # zpool create -o ashift=12 \
    #      -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
    #      -O xattr=sa -O mountpoint=/ -R /mnt \
    #               ${pool_name} /dev/mapper/luks1

    zfs create -o canmount=off -o mountpoint=none         ${pool_name}/root
    zfs create -o mountpoint=legacy                       ${pool_name}/root/nixos
    zfs create -o mountpoint=legacy -o setuid=off         ${pool_name}/home
    zfs create -o mountpoint=/root                        ${pool_name}/home/root

    # set boot property
    zpool set bootfs="${pool_name}/root/nixos" ${pool_name}

    zfs create -V 4G -b $(getconf PAGESIZE) \
               -o compression=zle \
               -o logbias=throughput -o sync=always \
               -o primarycache=metadata -o secondarycache=none \
               -o com.sun:auto-snapshot=false ${pool_name}/swap
  '';

  # T580
  # zpool create -o ashift=12 -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD -O xattr=sa -O mountpoint=/ -R /mnt -f rt580 /dev/nvme0n1p6
  # fileSystems."/" = { device = "rt580/local/root"; fsType = "zfs"; };
  # fileSystems."/boot" = { device = "/dev/disk/by-uuid/FE98-E8BD"; fsType = "vfat"; };
  # fileSystems."/nix" = { device = "rt580/local/nix"; fsType = "zfs"; neededForBoot=true; };
  # fileSystems."/home" = { device = "rt580/safe/home"; fsType = "zfs"; };
  # fileSystems."/root" = { device = "rt580/safe/home/root"; fsType = "zfs"; };
  # fileSystems."/persist" = { device = "rt580/safe/persist"; fsType = "zfs"; neededForBoot=true; };

  # zfs create -p -o mountpoint=legacy rt580/local/root
  # zfs snapshot rt580/local/root@blank
  # mount -t zfs rt580/local/root /mnt
  # mkdir /mnt/boot
  # mount /dev/disk/by-uuid/FE98-E8BD /mnt/boot
  # zfs create -p -o mountpoint=legacy rt580/local/nix
  # mkdir /mnt/nix
  # mount -t zfs rt580/local/nix /mnt/nix
  # zfs create -p -o mountpoint=legacy rt580/safe/home
  # mkdir /mnt/home
  # mount -t zfs rt580/safe/home /mnt/home
  # zfs create -p -o mountpoint=legacy rt580/safe/home/root
  # mkdir /mnt/home/root
  # mount -t zfs rt580/safe/home/root /mnt/home/root
  # zfs create -p -o mountpoint=legacy rt580/safe/persist
  # mkdir /mnt/persist
  # mount -t zfs rt580/safe/persist /mnt/persist

  # nixos-install --system /nix/store/87wcv7a9zg06jf7yih2n3s9xvw60l2al-nixos-system-t580-21.03.20210107.d92c727

  ## https://grahamc.com/blog/erase-your-darlings
  #boot.initrd.postDeviceCommands = lib.mkAfter ''
  #  zfs rollback -r rt580/local/root@blank
  #''

in {
  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.supportedFilesystems = [ "zfs" ];
  users.extraUsers.root.initialPassword = lib.mkForce "OhPha3gu";
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
  ];
  # Select internationalisation properties.
  console.font = "Lat2-Terminus16";
  console.keyMap = "fr";
  i18n.defaultLocale = "en_US.UTF-8";
  console.earlySetup = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  environment.systemPackages = [
    (pkgs.writeScriptBin "install-titan" ''
      #!${pkgs.stdenv.shell}
      set -eux -o pipefail
      ## https://github.com/zfsonlinux/zfs/wiki/Ubuntu-18.04-Root-on-ZFS
      #{concatMapStrings format_disk disks}

      #{zfs_create_mirror_pool "rpool" disks}
      #zpool import rpool

      #{concatMapStrings format_disk disks_st1000lm049}

      sleep 5
      ${zfs_create_raidz2_pool "icybox1" disks_st1000lm049}
      zpool import icybox1

      swapon -av

      # Mount the filesystems manually
      mount -t zfs icybox1/root/nixos /mnt

      mkdir -p /mnt/home
      mount -t zfs icybox1/home /mnt/home

      mkdosfs -F 32 -n EFI1 ${head disks_st1000lm049}-part3
      mkdir -p /mnt/boot/efi
      mount ${head disks_st1000lm049}-part3 /mnt/boot/efi/

      mkdir -p /mnt/etc/nixos/
      cp -v ${./titan/configuration.nix} /mnt/etc/nixos/configuration.nix
      ${config.system.build.nixos-install}/bin/nixos-install

      ##umount /mnt/boot/efi
      ### For the second and subsequent disks (increment ubuntu-2 to -3, etc.):
      ##dd if=/dev/disk/by-id/scsi-SATA_disk1-part3 \
      ##   of=/dev/disk/by-id/scsi-SATA_disk2-part3
      ##efibootmgr -c -g -d /dev/disk/by-id/scsi-SATA_disk2 \
      ##       -p 3 -L "ubuntu-2" -l '\EFI\Ubuntu\grubx64.efi'

      #umount /mnt
    '')
];

}

