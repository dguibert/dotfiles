{ config, pkgs, lib, ... }:

with lib;
#let
#  nodes = import ../../modules/infra.nix;
#in

rec {
  #sdImage.bootSize = 512;

  networking.hostName = "rpi41";

  # !!! This is only for ARMv6 / ARMv7. Don't enable this on AArch64, cache.nixos.org works there.
  #nix.binaryCaches = lib.mkForce [ "http://nixos-arm.dezgeg.me/channel" ];
  #nix.binaryCachePublicKeys = [ "nixos-arm.dezgeg.me-1:xBaUKS3n17BZPKeyxL4JfbTqECsT+ysbDJz29kLFRW0=%" ];

  ## !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
  #boot.kernelParams = ["cma=32M" "console=ttyS0,115200n8" "console=ttyAMA0,115200n8" "console=tty0"];

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
  #swapDevices = [ { device = "/swapfile"; size = 1024; } ];

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
      networkConfig.BindCarrier = "end0 wlan0";
      linkConfig.MACAddress = "DC:A6:32:67:DD:9F";
    };
  } // listToAttrs (flip map [ "end0" "wlan0" ] (bi:
    nameValuePair "40-${bi}" {
      name = "${bi}";
      DHCP = "no";
      networkConfig.Bond = "bond0";
      networkConfig.IPv6PrivacyExtensions = "kernel";
      linkConfig.MACAddress = "DC:A6:32:67:DD:9F";
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
}