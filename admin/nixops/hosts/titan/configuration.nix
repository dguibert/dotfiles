# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, utils, ... }:

with utils;
let
  migrate = fs1: fs2: {
    device = "none";
    fsType = "migratefs";
    #neededForBoot = true;
    options =
      [ # Filesystem options
      "allow_other,lowerdir=${fs1},upperdir=${fs2}"
      #"nofail"
      "X-mount.mkdir"
      "x-systemd.requires-mounts-for=${fs1}"
      "x-systemd.requires-mounts-for=${fs2}"
    ];
  };
in
rec {
  imports = [
      ../common.nix
      ../../modules/nix-conf.nix
      ../../modules/zfs.nix
      ../../modules/yubikey-gpg.nix
      #(import <nur_dguibert/modules>).qemu-user
      #../../modules/wayland-nvidia.nix
    ];
  #nesting.clone = [
  #  {
  #    imports = [
  #      ../../modules/wayland-nvidia.nix
  #    ];
  #    boot.loader.grub.configurationName = "Wayland NVIDIA";
  #  }
  #];

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "isci" "usbhid" "usb_storage" "sd_mod" "nvme" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.initrd.extraModprobeConfig = ''
    # 24G
    options zfs zfs_arc_max=25769803776
    options zfs zfs_vdev_scheduler="none"
    # use the prefetch method
    options zfs zfs_prefetch_disable=0

    options zfs zfs_dirty_data_max_percent=40
    options zfs zfs_txg_timeout=15
  '';
  boot.extraModprobeConfig = config.boot.initrd.extraModprobeConfig;

  # migrate-fs
  system.fsPackages = [ pkgs.fuse-migratefs ];
  boot.initrd.kernelModules = [ "fuse" ];
  boot.initrd.extraUtilsCommands = ''
    copy_bin_and_libs ${pkgs.fuse}/sbin/mount.fuse
    copy_bin_and_libs ${pkgs.fuse-migratefs}/bin/migratefs
    ln -sv $out/bin/migratefs $out/bin/mount.migratefs
    ln -sv $out/bin/migratefs $out/bin/mount.fuse.migratefs
  '';
  # from unionfs-fuse.nix
  boot.initrd.postDeviceCommands = ''
    # Hacky!!! fuse hard-codes the path to mount
    mkdir -p /nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-${pkgs.util-linux.name}-bin/bin
    ln -s $(which mount) /nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-${pkgs.util-linux.name}-bin/bin
    ln -s $(which umount) /nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-${pkgs.util-linux.name}-bin/bin

    # https://grahamc.com/blog/erase-your-darlings
    #zfs rollback -r rpool_vanif0/local/root@blank
  '';

  fileSystems."/mnt/old-root"                       = { device = "icybox1/local/root"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/"                                   = { device = "rpool_vanif0/local/root"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };

  fileSystems."/mnt/old/nix"                        = { device = "icybox1/local/nix"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; neededForBoot=true; };
  fileSystems."/nix"                                = { device = "rpool_vanif0/local/nix"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; neededForBoot=true; };
  #fileSystems."/nix" = migrate "/mnt/old/nix" "/mnt/new/nix";

  fileSystems."/mnt/old/root"                       = { device = "icybox1/safe/home/root"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/root"                               = { device = "rpool_vanif0/safe/home/root"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  #fileSystems."/root" = migrate "/mnt/old/root" "/mnt/new/root";

  fileSystems."/home/dguibert"                      = { device = "rpool_vanif0/safe/home/dguibert"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/home/dguibert/Videos"               = { device = "rpool_vanif0/safe/home/dguibert/Videos"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/home/dguibert/Maildir/.notmuch"     = { device = "rpool_vanif0/safe/home/dguibert/notmuch"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/mnt/old/home/dguibert"                      = { device = "icybox1/safe/home/dguibert"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/mnt/old/home/dguibert/Videos"               = { device = "icybox1/safe/home/dguibert/Videos"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/mnt/old/home/dguibert/Maildir/.notmuch"     = { device = "icybox1/safe/home/dguibert/notmuch"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  #fileSystems."/home/dguibert"                      = migrate "/mnt/old/home/dguibert" "/mnt/new/home/dguibert";
  #fileSystems."/home/dguibert/Videos"               = migrate "/mnt/old/home/dguibert/Videos" "/mnt/new/home/dguibert/Videos";
  #fileSystems."/home/dguibert/Maildir/.notmuch"     = migrate "/mnt/old/home/dguibert/Maildir/.notmuch" "/mnt/new/home/dguibert/Maildir/.notmuch";

  fileSystems."/persist"                            = { device = "rpool_vanif0/safe/persist"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; neededForBoot=true; };
  fileSystems."/mnt/old/persist"                            = { device = "icybox1/safe/persist"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; neededForBoot=true; };
  #fileSystems."/persist" = (migrate "/mnt/old/persist" "/mnt/new/persist") // { neededForBoot=true; };

  fileSystems."/boot/efi"                           = { label = "EFI1"; fsType = "vfat"; options = [ "x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto" ]; };
  fileSystems."/boot/efi1" = { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DDD965-part4"; fsType="vfat"; options = [ "x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto" "X-mount.mkdir" ]; };
  fileSystems."/boot/efi2" = { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DDDAD0-part4"; fsType="vfat"; options = [ "x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto" "X-mount.mkdir" ]; };
  fileSystems."/boot/efi3" = { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DDDAD3-part4"; fsType="vfat"; options = [ "x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto" "X-mount.mkdir" ]; };
  fileSystems."/boot/efi4" = { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DE3940-part4"; fsType="vfat"; options = [ "x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto" "X-mount.mkdir" ]; };
  fileSystems."/boot/efi5" = { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DE3947-part4"; fsType="vfat"; options = [ "x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto" "X-mount.mkdir" ]; };
  fileSystems."/boot/efi6" = { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DE3994-part4"; fsType="vfat"; options = [ "x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto" "X-mount.mkdir" ]; };

  fileSystems."/tmp"                                = { device="tmpfs"; fsType="tmpfs"; options= [ "defaults" "noatime" "mode=1777" "size=50G" ]; neededForBoot=true; };
  #fileSystems."/tmp"                                = { device="icybox1/local/tmp"; fsType="zfs"; options= [ "defaults" "noatime" "mode=1777" ]; neededForBoot=true; };
  fileSystems."/mnt/old/home_nfs/bguibertd/nix"             = { device = "icybox1/local/nix--home_nfs-bguibertd-nix"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/mnt/old/home_nfs_robin_ib/bguibertd/nix"    = { device = "icybox1/local/nix--home_nfs_robin_ib-bguibertd-nix"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/mnt/old/p/project/prcoe08/guibert1/nix"     = { device = "icybox1/local/nix--p-project-prcoe08-guibert1-nix"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/mnt/old/cluster/projects/nn9560k/dguibert"  = { device = "icybox1/local/nix--cluster-projects-nn9560k-dguibert"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };

  fileSystems."/home_nfs/bguibertd/nix"             = { device = "rpool_vanif0/local/nix--home_nfs-bguibertd-nix"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/home_nfs_robin_ib/bguibertd/nix"    = { device = "rpool_vanif0/local/nix--home_nfs_robin_ib-bguibertd-nix"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/p/project/prcoe08/guibert1/nix"     = { device = "rpool_vanif0/local/nix--p-project-prcoe08-guibert1-nix"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  fileSystems."/cluster/projects/nn9560k/dguibert"  = { device = "rpool_vanif0/local/nix--cluster-projects-nn9560k-dguibert"; fsType = "zfs"; options = [ "X-mount.mkdir" ]; };
  #fileSystems."/home_nfs/bguibertd/nix"             = migrate "/mnt/old/home_nfs/bguibertd/nix" "/mnt/new/home_nfs/bguibertd/nix";
  #fileSystems."/home_nfs_robin_ib/bguibertd/nix"    = migrate "/mnt/old/home_nfs_robin_ib/bguibertd/nix" "/mnt/new/home_nfs_robin_ib/bguibertd/nix";
  #fileSystems."/p/project/prcoe08/guibert1/nix"     = migrate "/mnt/old/p/project/prcoe08/guibert1/nix" "/mnt/new/p/project/prcoe08/guibert1/nix";
  #fileSystems."/cluster/projects/nn9560k/dguibert"  = migrate "/mnt/old/cluster/projects/nn9560k/dguibert" "/mnt/new/cluster/projects/nn9560k/dguibert";

  # Maintenance target for later
  # https://www.immae.eu/blog/tag/nixos.html
  systemd.targets.maintenance = {
    description = "Maintenance target with only sshd";
    after = [ "network-online.target" "network-setup.service" "sshd.service" ];
    requires = [ "network-online.target" "network-setup.service" "sshd.service" ];
    unitConfig = {
      AllowIsolate = "yes";
    };
  };
  #systemctl isolate maintenance.target
  #systemctl stop systemd-journald systemd-journald.socket systemd-journald-dev-log.socket systemd-journald-audit.socket
  #rsync -aHAXS --delete --one-file-system / /mnt/

  boot.kernelParams = [ "console=console" "console=ttyS1,115200n8"
    "loglevel=6"
    #"resume=/dev/disk/by-id/nvme-CT1000P1SSD8_2014E299CA2B-part1"
    "resume=/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DDD965-part4"
    #"add_efi_memmap"
    #"acpi_osi="
    # pmd_set_huge: Cannot satisfy [mem 0xf8000000-0xf8200000] with a huge-page mapping due to MTRR override
    #https://lwn.net/Articles/635357/
    "nohugeiomap"
    "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1"
  ];
  boot.zfs.devNodes = "/dev/disk/by-id";
  swapDevices = [
    { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DDD965-part4"; randomEncryption.enable = true; }
    { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DDDAD0-part4"; randomEncryption.enable = true; }
    { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DDDAD3-part4"; randomEncryption.enable = true; }
    { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DE3940-part4"; randomEncryption.enable = true; }
    { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DE3947-part4"; randomEncryption.enable = true; }
    { device = "/dev/disk/by-id/nvme-CT1000P2SSD8_2143E5DE3994-part4"; randomEncryption.enable = true; }

    #{ device="/dev/disk/by-id/nvme-CT1000P1SSD8_2014E299CA2B-part1"; }
  ];

  nix.settings.max-jobs = lib.mkDefault 8;
  nix.settings.build-cores = lib.mkDefault 24;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.timeout = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  #boot.loader.grub.efiSupport = true;
  #boot.loader.grub.device = "nodev";
  console.earlySetup = true;
  console.useXkbConfig = true;

  networking.hostId="8425e349";
  networking.hostName = "titan";

  ##qemu-user.aarch64 = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" "armv7l-linux" ];
  ##boot.binfmt.registrations."aarch64-linux".preserveArgvZero=true;
  boot.binfmt.registrations."aarch64-linux".fixBinary=true;
  ##boot.binfmt.registrations."armv7l-linux".preserveArgvZero=true;
  boot.binfmt.registrations."armv7l-linux".fixBinary=true;

  services.openssh.enable = true;

  #boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.extraModulePackages = [ pkgs.linuxPackages.perf ];
  # *** ZFS Version: zfs-2.0.4-1
  # *** Compatible Kernels: 3.10 - 5.11
  boot.zfs.enableUnstable = false;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.09"; # Did you read the comment?

  networking.useNetworkd = lib.mkForce false;
  networking.dhcpcd.enable = false;
  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
    "" # clear old command
    "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --ignore eno1 --ignore eno2 --ignore enp0s29u1u1u3i5"
  ];
  systemd.network.netdevs."40-bond0" = {
    netdevConfig.Name = "bond0";
    netdevConfig.Kind = "bond";
    #[Bond]
    #Mode=active-backup
    #PrimaryReselectPolicy=always
    #PrimarySlave=enp3s0
    #TransmitHashPolicy=layer3+4
    #MIIMonitorSec=1s
    #LACPTransmitRate=fast

    bondConfig.Mode="802.3ad";
    #bondConfig.PrimarySlave="eno1";
  };
  systemd.network.networks."40-bond0" = {
    name = "bond0";
    DHCP = "yes";
    networkConfig.BindCarrier = "eno1 eno2";
  };
  systemd.network.networks."40-eno1" = {
    name = "eno1";
    DHCP = "no";
    networkConfig.Bond = "bond0";
    networkConfig.IPv6PrivacyExtensions = "kernel";
  };
  systemd.network.networks."40-eno2" = {
    name = "eno2";
    DHCP = "no";
    networkConfig.Bond = "bond0";
    networkConfig.IPv6PrivacyExtensions = "kernel";
  };

  # services.xserver.videoDrivers = [ "nvidia" ];
  #services.xserver.videoDrivers = [ "nvidiaLegacy340" ];
  ## [   13.576513] NVRM: The NVIDIA Quadro FX 550 GPU installed in this system is
  ##                NVRM:  supported through the NVIDIA 304.xx Legacy drivers. Please
  ##                NVRM:  visit http://www.nvidia.com/object/unix.html for more
  ##                NVRM:  information.  The 340.104 NVIDIA driver will ignore
  ##                NVRM:  this GPU.  Continuing probe...
  hardware.nvidia.modesetting.enable = true;
  services.xserver.videoDrivers = lib.mkIf config.services.xserver.enable [ "nvidia" /*"nouveau"*/ /*"nvidiaLegacy304"*/ /*"displaylink"*/ ];
  #nixpkgs.config.xorg.abiCompat = "1.18";

  # https://nixos.org/nixos/manual/index.html#sec-container-networking
  networking.nat.enable = true;
  networking.nat.internalInterfaces = ["ve-+"];
  networking.nat.externalInterface = "bond0";

  # https://wiki.archlinux.org/index.php/Improving_performance#Input/output_schedulers
  services.udev.extraRules = with pkgs; ''
    # set scheduler for NVMe
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    # set scheduler for SSD and eMMC
    ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    # set scheduler for rotating disks
    # udevadm info -a -n /dev/sda | grep queue
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="none"

    # set scheduler for ZFS member
    # udevadm info --query=all --name=/dev/sda
    # https://github.com/openzfs/zfs/pull/9609
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{ID_FS_TYPE}=="zfs_member", ATTR{queue/scheduler}="none"
    ACTION=="add|change", SUBSYSTEM=="block", ATTRS{ID_SERIAL_SHORT}=="WGS3EP4M", ATTR{queue/scheduler}="none"
    ACTION=="add|change", SUBSYSTEM=="block", ATTRS{ID_SERIAL_SHORT}=="WGS20WK1", ATTR{queue/scheduler}="none"
    ACTION=="add|change", SUBSYSTEM=="block", ATTRS{ID_SERIAL_SHORT}=="WGS25XFD", ATTR{queue/scheduler}="none"
    ACTION=="add|change", SUBSYSTEM=="block", ATTRS{ID_SERIAL_SHORT}=="WGS38E3P", ATTR{queue/scheduler}="none"
    ACTION=="add|change", SUBSYSTEM=="block", ATTRS{ID_SERIAL_SHORT}=="WGS20WGY", ATTR{queue/scheduler}="none"
    ACTION=="add|change", SUBSYSTEM=="block", ATTRS{ID_SERIAL_SHORT}=="WGS1T415", ATTR{queue/scheduler}="none"

  '';

  services.sanoid = {
    enable = true;
    interval = "*:00,15,30,45"; #every 15minutes
    templates.prod = {
      frequently = 8;
      hourly = 24;
      daily = 7;
      monthly = 3;
      yearly = 0;

      autosnap = true;
    };
    templates.media = {
      hourly = 4;
      daily = 2;
      monthly = 2;
      yearly = 0;

      autosnap = true;
    };
    datasets."icybox1/safe".use_template = [ "prod" ];
    datasets."icybox1/safe".recursive = true;
    datasets."icybox1/safe/home/dguibert/Videos".use_template = [ "media" ];
    datasets."icybox1/safe/home/dguibert/Videos".recursive = true;

    datasets."rpool_vanif0/local/root".use_template = [ "prod" ];
    datasets."rpool_vanif0/safe".use_template = [ "prod" ];
    datasets."rpool_vanif0/safe".recursive = true;
    datasets."rpool_vanif0/safe/home/dguibert/Videos".use_template = [ "media" ];
    datasets."rpool_vanif0/safe/home/dguibert/Videos".recursive = true;

    templates.backup = {
      autoprune = true;
      ### don't take new snapshots - snapshots on backup
      ### datasets are replicated in from source, not
      ### generated locally
      autosnap = false;

      frequently = 0;
      hourly = 36;
      daily = 30;
      monthly = 12;
    };
    datasets."st4000dm004-1/backup/icybox1".use_template = [ "backup" ];
    datasets."st4000dm004-1/backup/icybox1".recursive = true;

    extraArgs = [ "--verbose" ];
  };

  boot.zfs.extraPools = [ "st4000dm004-1" ];

  services.syncoid = {
    enable = true;
    #sshKey = "/root/.ssh/id_ecdsa";
    commonArgs = [ "--no-sync-snap" "--debug" /*"--create-bookmark"*/ ];
    #commands."pool/test".target = "root@target:pool/test";
    commands."rpool_vanif0/local/root".target = "st4000dm004-1/backup/rpool_vanif0/local/root";
    commands."rpool_vanif0/safe".target = "st4000dm004-1/backup/rpool_vanif0/safe";
    commands."rpool_vanif0/safe".recursive = true;
  };

}
