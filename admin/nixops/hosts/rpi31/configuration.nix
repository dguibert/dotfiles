{ config, pkgs, lib, inputs, ... }:

with lib;
#let
#  nodes = import ../../modules/infra.nix;
#in

rec {
  imports = [
    (import "${inputs.nixpkgs.inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
    ../../modules/nixos/defaults
  ];
  #sdImage.bootSize = 512;

  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  #boot.loader.generic-extlinux-compatible.enable = true;
  #boot.loader.generic-extlinux-compatible.configurationLimit = 10;
  #boot.loader.raspberryPi.uboot.enable = true;
  #boot.loader.raspberryPi.enable = true;
  #boot.loader.raspberryPi.version = 3;

  # !!! If your board is a Raspberry Pi 1, select this:
  #boot.kernelPackages = pkgs.linuxPackages_rpi;
  # !!! Otherwise (even if you have a Raspberry Pi 2 or 3), pick this:
  #boot.kernelPackages = pkgs.linuxPackages_rpi3;
  #nixpkgs.overlays = [
  #  (final: prev: {
  #    makeModulesClosure = { kernel, firmware, rootModules, allowMissing ? false }: prev.makeModulesClosure
  #      {
  #        inherit kernel firmware rootModules;
  #        allowMissing = true;
  #      };
  #  })
  #];
  #boot.supportedFilesystems = [ "zfs" ];
  boot.supportedFilesystems = mkForce [ /*"btrfs" "reiserfs"*/ "vfat" "f2fs" /*"xfs" "zfs"*/ "ntfs" /*"cifs"*/ ];
  boot.postBootCommands = ''
    ${pkgs.nettools}/bin/mii-tool -v -R eth0
  '';
  #boot.zfs.enableUnstable = true;
  networking.hostId = "8425e349";
  networking.hostName = "rpi31";

  ## File systems configuration for using the installer's partition layout
  #fileSystems = {
  #  "/boot" = {
  #    device = "/dev/disk/by-label/NIXOS_BOOT";
  #    fsType = "vfat";
  #  };
  #  "/" = {
  #    device = "/dev/disk/by-label/NIXOS_SD";
  #    fsType = "ext4";
  #  };
  #};

  # !!! Adding a swap file is optional, but strongly recommended!
  swapDevices = [{ device = "/swapfile"; size = 1024; }];

  environment.systemPackages = [ pkgs.vim ];

  nix.settings.max-jobs = 4;

  networking.useNetworkd = lib.mkForce false;
  systemd.network.enable = lib.mkForce true;
  networking.dhcpcd.enable = false;
  systemd.network.wait-online.anyInterface = true;

  systemd.network.netdevs."40-bond0" = {
    netdevConfig.Name = "bond0";
    netdevConfig.Kind = "bond";
    bondConfig.Mode = "active-backup";
    bondConfig.MIIMonitorSec = "100s";
    bondConfig.PrimaryReselectPolicy = "always";
  };
  systemd.network.networks = {
    "40-bond0" = {
      name = "bond0";
      DHCP = "yes";
      networkConfig.BindCarrier = "eth0 wlan0";
      linkConfig.MACAddress = "b8:27:eb:46:86:14";
    };
  } // listToAttrs (flip map [ "eth0" "wlan0" ] (bi:
    nameValuePair "40-${bi}" {
      name = "${bi}";
      DHCP = "no";
      networkConfig.Bond = "bond0";
      networkConfig.IPv6PrivacyExtensions = "kernel";
      linkConfig.MACAddress = "b8:27:eb:46:86:14";
    }));
  networking.supplicant.wlan0 = {
    configFile.path = "/persist/etc/wpa_supplicant.conf";
    userControlled.group = "network";
    extraConf = ''
      ap_scan=1
      p2p_disabled=1
    '';
    extraCmdArgs = "-u";
  };



  environment.noXlibs = false; #https://github.com/NixOS/nixpkgs/issues/102137
  programs.ssh.setXAuthLocation = false;
  security.pam.services.su.forwardXAuth = lib.mkForce false;

  fonts.fontconfig.enable = false;

  sops.defaultSopsFile = ./secrets/secrets.yaml;
}
