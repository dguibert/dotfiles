####{ config, nodes, pkgs, lib, ...}@attrs:
####with lib;
####rec {
####  imports = [
####    ./orsine/configuration.nix
####    ./common.nix
####  ] ++ (import ../services/service-list.nix) { attr = "orsine"; } attrs;
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

rec {

  imports = [
    ../common.nix
  ];
  nixpkgs.localSystem.system = "x86_64-linux";

  # Use the GRUB 2 boot loader.
  boot.loader.grub.device = "/dev/disk/by-id/ata-Samsung_SSD_840_PRO_Series_S12PNEAD231035B";
  boot.kernelParams = ["resume=/dev/disk/by-id/ata-Samsung_SSD_840_PRO_Series_S12PNEAD231035B-part2" ];
  boot.loader.grub.configurationLimit = 10;

  boot.kernelModules = [ "fuse" "kvm-intel" ];
  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "usb_storage" "tm-smapi" ];
  boot.kernelPackages = pkgs.linuxPackages_5_13;
  boot.extraModulePackages = [ pkgs.linuxPackages.perf config.boot.kernelPackages.tp_smapi ];
#  nixpkgs.config = {pkgs}: (import ../../config/nixpkgs/config.nix { inherit pkgs; }) // {
#    allowUnfree = true;
#    packageOverrides.linuxPackages = boot.kernelPackages;
#  };
  boot.supportedFilesystems = [ "zfs" ];
  #boot.zfs.enableUnstable = true; # Linux v4.18.1 is not yet supported by zfsonlinux v0.7.9

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/cc74b0e1-c5fb-4bf2-870a-e23363cd7849";
      fsType = "xfs";
    };
  fileSystems."/tmp" = { device="tmpfs"; options= [ "defaults" "noatime" "mode=1777" "size=3G" ]; fsType="tmpfs"; neededForBoot=true; };

  swapDevices = [ { device = "/dev/sda2"; } ];

  nix.settings.max-jobs = 2;

  hardware.trackpoint.enable = true;
  hardware.trackpoint.emulateWheel = true;

  #  autoInstall = ''
  # https://wiki.archlinux.org/index.php/ZFS#Root_on_ZFS
  #  zpool create -o feature@multi_vdev_crash_dump=disabled \
  #                  -o feature@large_dnode=disabled        \
  #                  -o feature@sha512=disabled             \
  #                  -o feature@skein=disabled              \
  #                  -o feature@edonr=disabled              \
  #		  -o feature@encryption=disabled         \
  #                  $POOL_NAME $VDEVS
  #  zfs create -o setuid=off -o devices=off -o sync=disabled -o mountpoint=/tmp <pool>/tmp
  #  systemctl mask tmp.mount
  #  zfs create <nameofzpool>/<nameofdataset>
  #  zfs set quota=20G <nameofzpool>/<nameofdataset>/<directory>
  #  # zfs create -V 8G -b $(getconf PAGESIZE) \
  #               -o logbias=throughput -o sync=always\
  #               -o primarycache=metadata \
  #               -o com.sun:auto-snapshot=false <pool>/swap
  # # mkswap -f /dev/zvol/<pool>/swap
  # # swapon /dev/zvol/<pool>/swap
  #  '';

  networking.hostId = "a8c00e01";
  networking.hostName = "orsine";

  #networking.wireless.iwd.enable = true; # wifi usb dongle does show in device list
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.wireless.interfaces = [ /*"wlp0s29f7u1"*/ "wlp0s26f7u1" ];
  networking.wireless.driver = "nl80211,wext";
  networking.wireless.userControlled.enable = true;

  networking.useNetworkd = lib.mkForce false;
  networking.dhcpcd.enable = false;
  systemd.network.netdevs."40-bond0" = {
    netdevConfig.Name = "bond0";
    netdevConfig.Kind = "bond";
    bondConfig.Mode="active-backup";
    bondConfig.MIIMonitorSec="100s";
    bondConfig.PrimaryReselectPolicy="always";
  };
  systemd.network.networks."40-bond0" = {
    name = "bond0";
    DHCP = "yes";
    networkConfig.BindCarrier = "enp0s25 wlp0s29f7u1";
  };
#  systemd.network.networks = listToAttrs (flip map [ "enp0s25" "wlp0s26f7u1" ] (bi:
#    nameValuePair "40-${bi}" {
#      DHCP = "none";
#      networkConfig.Bond = "bond0";
#      networkConfig.IPv6PrivacyExtensions = "kernel";
#    }));
  #systemd.network.networks."99-main".name = "!zt0 wlp2s0";
  systemd.network.networks."40-enp0s25" = {
    name = "enp0s25";
    DHCP = "no";
    networkConfig.Bond = "bond0";
    #networkConfig.PrimarySlave=true;
    networkConfig.IPv6PrivacyExtensions = "kernel";
  };
  systemd.network.networks."40-wlp0s29f7u1" = {
    name = "wlp0s29f7u1";
    DHCP = "no";
    networkConfig.Bond = "bond0";
    #networkConfig.ActiveSlave=false;
    networkConfig.IPv6PrivacyExtensions = "kernel";
  };
  systemd.network.networks."40-wlp0s26f7u1" = {
    name = "wlp0s26f7u1";
    DHCP = "yes";
  };
  #{networking.bonds.bond0.interfaces = [ "enp0s25" /*"wlp0s26f7u1"*/ ];
  #{boot.extraModprobeConfig=''
  #{  options bonding mode=active-backup miimon=100 primary=enp0s25
  #{'';
  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
    "" # clear old command
    "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --ignore wlp0s29f7u1 --ignore wlp2s0 --ignore enp0s25 --ignore vboxnet0"
  ];

  hardware.bluetooth.enable = true;

  services.logind.extraConfig = "LidSwitchIgnoreInhibited=no";

  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudio.override {
      /*gconf = gnome3.gconf;*/
      x11Support = true;
      /*gconfSupport = true;*/
      bluetoothSupport = true;
    };
  };
  services.tlp.enable = true;

  nixpkgs.config.allowUnfree = true;
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; let
      myTexLive = texlive.combine {
        inherit (texlive) scheme-small beamer pgf algorithms cm-super;
      };
    in [
    vim htop lsof
    wget telnet
    bc
    git
    gnuplot graphviz imagemagick
    diffstat diffutils binutils zip unzip
    unrar cabextract cpio lzma which file
    acpitool iputils
    fuse sshfsFuse
    manpages gnupg tree
# lsof - shows open files/sockets, including network
    lsof
    vim ethtool
    wirelesstools wpa_supplicant_gui
    alsaPlugins pavucontrol

    nixops
    config.boot.kernelPackages.perf
  ] ++ (with aspellDicts; [en fr]) ++ [
    rxvt_unicode
    pkgs.disnixos pkgs.wireguard-tools
  ];

  # for X11.nix
  services.xserver.resolutions = [{x=1440; y=900;}];
  services.xserver.videoDrivers = [ "intel" ];
  hardware.opengl.extraPackages = [ pkgs.vaapiIntel ];

#  programs.sysdig.enable = true;

  programs.bash.enableCompletion = true;
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.ports = [22322];
  #services.wakeonlan.interfaces = [
  #  {
  #    interface = "enp0s25";
  #    method = "magicpacket";
  #    #method = "password";
  #    #password = "00:11:22:33:44:55";
  #  }
  #];

  # Virtualisation
  #virtualisation.virtualbox.host.enable = true;
  #virtualisation.virtualbox.host.enableHardening = false;
  virtualisation.libvirtd.enable = true;
  systemd.tmpfiles.rules = [ "d /var/lib/libvirt/images 1770 root libvirtd -" ];

  services.udev.packages = [ pkgs.android-udev-rules ];
  services.udev.extraRules = with pkgs; ''
    # This files changes the mode of the Dynastream ANT UsbStick2 so all users can read and write to it.
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fcf", ATTR{idProduct}=="1008", MODE="0666", SYMLINK+="ttyANT", ACTION=="add"
  '';

  #virtualisation.libvirtd.enable = true;
  networking.firewall.checkReversePath = false;

  # ChromeCast ports
  # iptables -I INPUT -p udp -m udp --dport 32768:61000 -j ACCEPT
  networking.firewall.allowedUDPPortRanges = [ { from=32768; to=61000; } ];

  # (evince:16653): dconf-WARNING **: failed to commit changes to dconf:
  # GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name
  # ca.desrt.dconf was not provided by any .service files
  services.dbus.packages = with pkgs; [ pkgs.dconf ];

  ## /dev/disk/by-id/ata-WDC_WD10TMVV-11TK7S1_WD-WXL1E61NHVC1-part9
  ## /dev/disk/by-id/ata-WDC_WD10TMVV-11TK7S1_WD-WXL1E61PEJW5-part9
  ## /dev/disk/by-id/ata-WDC_WD10TMVV-11TK7S1_WD-WXL1E61NTXH5-part9
  ##
  ##[Unit]
  ##After=dev-disk-by\x2did-wwn\x2d0x60014057ab42867d066fd393edb4abd6.device
  ##
  ##[Service]
  ##ExecStart=/usr/sbin/zpool import itank
  ##ExecStartPost=/usr/bin/logger "started ZFS pool itank"
  ##
  ##[Install]
  ##WantedBy=dev-disk-by\x2did-wwn\x2d0x60014057ab42867d066fd393edb4abd6.device
  systemd.services.zfs-import-backupwd = {
    description = "automatically import backupwd zpool";
    after = [
      "dev-disk-by\\x2did-ata\\x2dWDC_WD10TMVV\\x2d11TK7S1_WD\\x2dWXL1E61NHVC1\\x2dpart9.device"
      "dev-disk-by\\x2did-ata\\x2dWDC_WD10TMVV\\x2d11TK7S1_WD\\x2dWXL1E61PEJW5\\x2dpart9.device"
      "dev-disk-by\\x2did-ata\\x2dWDC_WD10TMVV\\x2d11TK7S1_WD\\x2dWXL1E61NTXH5\\x2dpart9.device"
    ];
    wantedBy = [
      "dev-disk-by\\x2did-ata\\x2dWDC_WD10TMVV\\x2d11TK7S1_WD\\x2dWXL1E61NHVC1\\x2dpart9.device"
      "dev-disk-by\\x2did-ata\\x2dWDC_WD10TMVV\\x2d11TK7S1_WD\\x2dWXL1E61PEJW5\\x2dpart9.device"
      "dev-disk-by\\x2did-ata\\x2dWDC_WD10TMVV\\x2d11TK7S1_WD\\x2dWXL1E61NTXH5\\x2dpart9.device"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.zfs}/sbin/zpool import backupwd";
      #ExecStartPost = "logger \"started ZFS pool backupwd\"";
    };
  };

}
