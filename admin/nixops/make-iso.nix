# https://github.com/snabblab/snabblab-nixos/blob/master/make-iso.nix
# build an ISO image that will auto install NixOS and reboot
# $ nix-build make-iso.nix
{ inception ? false }:

let
   config = (import <nixpkgs/nixos/lib/eval-config.nix> {
     system = "x86_64-linux";
     modules = [
	<nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
       ({ pkgs, lib, ... }:
         let
           cfg = pkgs.writeText "configuration.nix" ''
            { config, pkgs, lib, ... }:

            {
              boot.loader.grub.enable = true;
              boot.loader.grub.devices = [ "/dev/sda" "/dev/sdb" ];
              boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "ehci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];

              boot.supportedFilesystems = [ "zfs" ];
              networking.hostId="8425e349";

              services.openssh.enable = true;
              services.openssh.startWhenNeeded = true;
              users.extraUsers.root.initialPassword = lib.mkForce "OhPha3gu";
              users.users.root.openssh.authorizedKeys.keys = [
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
           ];

              # Select internationalisation properties.
              i18n.consoleFont = "Lat2-Terminus16";
              i18n.consoleKeyMap = "fr";
              i18n.defaultLocale = "en_US.UTF-8";

              # Set your time zone.
              time.timeZone = "Europe/Paris";

              # this is set for install not to ask for password
              users.mutableUsers = false;

              fileSystems."/" =
      { device = "rpool/root/nixos";
        fsType = "zfs";
      };

    fileSystems."/home" =
      { device = "rpool/home";
        fsType = "zfs";
      };

            }
           '';
         in {
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

#           systemd.services.inception = lib.mkIf inception {
#             description = "Self-bootstrap a NixOS installation";
#             wantedBy = [ "multi-user.target" ];
#             after = [ "network.target" "polkit.service" ];
#             path = [ "/run/current-system/sw/" ];
#             script = with pkgs; ''
#               set -x
#               sleep 5
#               # https://github.com/zfsonlinux/zfs/wiki/Ubuntu-18.04-Root-on-ZFS
#               for disk in /dev/sda /dev/sdbr; do
#                 mdadm --zero-superblock --force $disk
#                 sgdisk --zap-all $disk
#                 # Run this if you need legacy (BIOS) booting:
#                 sgdisk -a1 -n2:34:2047  -t2:EF02 $disk
#
#                 #Run this for UEFI booting (for use now or in the future):
#                 # sgdisk     -n3:1M:+512M -t3:EF00 $disk
#                 # Unencrypted:
#                 sgdisk     -n1:0:0      -t1:BF01 $disk
#                 #               LUKS:
#                 # sgdisk     -n4:0:+512M  -t4:8300 $disk
#                 # sgdisk     -n1:0:0      -t1:8300 $disk
#               done
#
#
#               # Unencrypted:
#               zpool create -o ashift=12 \
#                     -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
#                     -O xattr=sa -O mountpoint=/ -R /mnt \
#                     rpool mirror /dev/sda1 /dev/sdb1
#               # LUKS:
#               # cryptsetup luksFormat -c aes-xts-plain64 -s 256 -h sha256 \
#               #      $disk-part1
#               # cryptsetup luksOpen $disk-part1 luks1
#               # zpool create -o ashift=12 \
#               #      -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
#               #      -O xattr=sa -O mountpoint=/ -R /mnt \
#               #               rpool /dev/mapper/luks1
#
#               zfs create -o canmount=off -o mountpoint=none rpool/root
#               zfs create -o canmount=noauto -o mountpoint=/ rpool/root/nixos
#               zfs mount rpool/root/nixos
#               zfs create -o mountpoint=legacy -o setuid=off         rpool/home
#               zfs create -o mountpoint=/root                        rpool/home/root
#
#               # Mount the filesystems manually
#               mount -t zfs rpool/root/nixos /mnt
#               
#               mkdir /mnt/home
#               mount -t zfs rpool/home /mnt/home
#               
#               # Create a raid mirror of the first partitions for /boot (GRUB)
#               mdadm --create /dev/md127 --metadata=0.90 --level=1 --raid-devices=2 /dev/sd[a,b]2
#               mkfs.ext4 -m 0 -L boot -j /dev/md127
#               mkdir /mnt/boot
#               mount /dev/md127 /mnt/boot
#
#               mkdir -p /mnt/etc/nixos/
#               cp ${cfg} /mnt/etc/nixos/configuration.nix
#               ${config.system.build.nixos-install}/bin/nixos-install -j 2
#               ${systemd}/bin/shutdown -r now
#             '';
#             environment = config.nix.envVars // {
#               inherit (config.environment.sessionVariables) NIX_PATH /*SSL_CERT_FILE missing */;
#               HOME = "/root";
#             };
#             serviceConfig = {
#               Type = "oneshot";
#             };
#           };
       })
     ];
   }).config;
in
  config.system.build.isoImage
