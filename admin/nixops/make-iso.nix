# https://github.com/snabblab/snabblab-nixos/blob/master/make-iso.nix
# build an ISO image that will auto install NixOS and reboot
# $ nix-build make-iso.nix

let
   config = (import <nixpkgs/nixos/lib/eval-config.nix> {
     system = "x86_64-linux";
     modules = [
	<nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
       ({ pkgs, lib, ... }: {
           boot.supportedFilesystems = [ "zfs" ];
           users.extraUsers.root.initialPassword = lib.mkForce "OhPha3gu";
           services.openssh.enable = true;
           services.openssh.startWhenNeeded = true;
           users.users.root.openssh.authorizedKeys.keys = [
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
           ];
           # Select internationalisation properties.
           i18n.consoleFont = "Lat2-Terminus16";
           i18n.consoleKeyMap = "fr";
           i18n.defaultLocale = "en_US.UTF-8";

           # Set your time zone.
           time.timeZone = "Europe/Paris";
           
           environment.systemPackages = [ 
             (pkgs.writeScriptBin "install-titan" ''
#!${pkgs.stdenv.shell}

## https://github.com/zfsonlinux/zfs/wiki/Ubuntu-18.04-Root-on-ZFS
dd if=/dev/zero of=/dev/disk/by-id/ata-ST3160812AS_5LS8DN8Z bs=512 count=10000
sgdisk -o /dev/disk/by-id/ata-ST3160812AS_5LS8DN8Z || true
sgdisk -o /dev/disk/by-id/ata-ST3160812AS_5LS8DN8Z || true
sgdisk -o /dev/disk/by-id/ata-ST3160812AS_5LS8DN8Z || true

dd if=/dev/zero of=/dev/disk/by-id/ata-ST3160815AS_5RX02WNE bs=512 count=10000
sgdisk -o /dev/disk/by-id/ata-ST3160815AS_5RX02WNE || true
sgdisk -o /dev/disk/by-id/ata-ST3160815AS_5RX02WNE || true
sgdisk -o /dev/disk/by-id/ata-ST3160815AS_5RX02WNE || true

# Run this if you need legacy (BIOS) booting:
#  sgdisk -a1 -n2:34:2047  -t2:EF02 $disk

#Run this for UEFI booting (for use now or in the future):
sgdisk     -n3:1M:+512M -t3:EF00 /dev/disk/by-id/ata-ST3160812AS_5LS8DN8Z
sgdisk     -n3:1M:+512M -t3:EF00 /dev/disk/by-id/ata-ST3160815AS_5RX02WNE

#  # Unencrypted:
#  sgdisk     -n1:0:0      -t1:BF01 $disk
sgdisk     -n1:0:0      -t1:BF01 /dev/disk/by-id/ata-ST3160815AS_5RX02WNE
sgdisk     -n1:0:0      -t1:BF01 /dev/disk/by-id/ata-ST3160812AS_5LS8DN8Z

#               LUKS:
# sgdisk     -n4:0:+512M  -t4:8300 $disk
# sgdisk     -n1:0:0      -t1:8300 $disk

# Unencrypted:
zpool create -o ashift=12 \
      -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
      -O xattr=sa -O mountpoint=/ -R /mnt \
      -f \
      rpool mirror /dev/disk/by-id/ata-ST3160812AS_5LS8DN8Z-part1 \
                   /dev/disk/by-id/ata-ST3160815AS_5RX02WNE-part1
# LUKS:
# cryptsetup luksFormat -c aes-xts-plain64 -s 256 -h sha256 \
#      $disk-part1
# cryptsetup luksOpen $disk-part1 luks1
# zpool create -o ashift=12 \
#      -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
#      -O xattr=sa -O mountpoint=/ -R /mnt \
#               rpool /dev/mapper/luks1

zfs create -o canmount=off -o mountpoint=none         rpool/root
zfs create -o mountpoint=legacy                       rpool/root/nixos
zfs create -o mountpoint=legacy -o setuid=off         rpool/home
zfs create -o mountpoint=/root                        rpool/home/root

zfs create -V 4G -b $(getconf PAGESIZE) \
           -o compression=zle \
           -o logbias=throughput -o sync=always \
           -o primarycache=metadata -o secondarycache=none \
           -o com.sun:auto-snapshot=false rpool/swap

zpool import rpool

swapon -av

# Mount the filesystems manually
mount -t zfs rpool/root/nixos /mnt

mkdir -p /mnt/home
mount -t zfs rpool/home /mnt/home

# set boot property
zpool set bootfs="rpool/root/nixos" rpool

mkdosfs -F 32 -n EFI /dev/disk/by-id/ata-ST3160812AS_5LS8DN8Z-part3
mkdir -p /mnt/boot/efi
mount /dev/disk/by-id/ata-ST3160812AS_5LS8DN8Z-part3 /mnt/boot/efi/

mkdir -p /mnt/etc/nixos/
cp -v ${./titan/configuration.nix} /mnt/etc/nixos/configuration.nix
cp -v ${./titan/hardware-configuration.nix} /mnt/etc/nixos/hardware-configuration.nix
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

       })
     ];
   }).config;
in
  config.system.build.isoImage
