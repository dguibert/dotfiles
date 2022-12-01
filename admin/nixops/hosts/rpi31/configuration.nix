{ config, pkgs, lib, ... }:

with lib;
#let
#  nodes = import ../../modules/infra.nix;
#in

rec {
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
  boot.kernelPackages = pkgs.linuxPackages_5_15;
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
  networking.dhcpcd.enable = false;
  systemd.network.networks."eth0" = {
    name = "eth0";
    DHCP = "yes";
  };

  environment.noXlibs = false; #https://github.com/NixOS/nixpkgs/issues/102137
  programs.ssh.setXAuthLocation = false;
  security.pam.services.su.forwardXAuth = lib.mkForce false;

  fonts.fontconfig.enable = false;

  sops.defaultSopsFile = ./secrets/secrets.yaml;
}
