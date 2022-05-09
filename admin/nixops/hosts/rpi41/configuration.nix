{ config, pkgs, lib, ... }:

with lib;
#let
#  nodes = import ../../modules/infra.nix;
#in

rec {
  #imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix> ];
  imports = [
    ../common.nix
  ];

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

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.listenAddresses = [
    { addr = "127.0.0.1"; port=22; }
    { addr = "0.0.0.0"; port=22322; }
  ];

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

  networking.firewall.allowedTCPPorts = [ 22322 ];
}
