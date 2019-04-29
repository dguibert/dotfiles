{ config, pkgs, lib, ... }:

with lib;
#let
#  nodes = import <modules/infra.nix>;
#in

rec {
  #imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix> ];
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix>
    <nixpkgs/nixos/modules/profiles/minimal.nix>
    <config/common.nix>
    <modules/nix-conf.nix>
    <modules/distributed-build.nix>
    <config/users/dguibert>
    <config/users/rdolbeau>
  ];

  # see commit c6f7d4367894047592cc412740f0c1f5b2ca2b59
  nixpkgs.localSystem.system = "aarch64-linux";
  assertions = lib.singleton {
    assertion = pkgs.stdenv.system == "aarch64-linux";
    message = "rpi31-configuration.nix can be only built natively on Aarch64 / ARM64; " +
      "it cannot be cross compiled";
  };
  sdImage.bootSize = 512;

  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.generic-extlinux-compatible.configurationLimit = 2;

  # !!! If your board is a Raspberry Pi 1, select this:
  #boot.kernelPackages = pkgs.linuxPackages_rpi;
  # !!! Otherwise (even if you have a Raspberry Pi 2 or 3), pick this:
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "zfs" ];
  #boot.zfs.enableUnstable = true;
  networking.hostId = "8425e349";

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
  swapDevices = [ { device = "/swapfile"; size = 1024; } ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.ports = [22322 443 ];

  environment.systemPackages = [ pkgs.vim ];

  nix.maxJobs = 4;

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.147.27.13/24" ];
    listenPort = 500;
    privateKeyFile = toString <secrets/rpi31/wireguard_key>;
    peers = [
      { allowedIPs = [ "10.147.27.0/24" ];
        publicKey  = "wBBjx9LCPf4CQ07FKf6oR8S1+BoIBimu1amKbS8LWWo=";
        endpoint   = "orsin.freeboxos.fr:500";
	persistentKeepalive = 25;
      }
      { allowedIPs = [ "10.147.27.198/32" ];
        publicKey  = "rbYanMKQBY/dteQYQsg807neESjgMP/oo+dkDsC5PWU=";
        endpoint   = "orsin.freeboxos.fr:51821";
	persistentKeepalive = 25;
      }
      { allowedIPs = [ "10.147.27.123/32" ];
        publicKey  = "Z8yyrih3/vINo6XlEi4dC5i3wJCKjmmJM9aBr4kfZ1k=";
        endpoint   = "orsin.freeboxos.fr:51820";
	persistentKeepalive = 25;
      }
    ];
  };
  networking.firewall.allowedUDPPorts = [ 9993 500 ];

  environment.noXlibs = true;
  programs.ssh.setXAuthLocation = false;
  security.pam.services.su.forwardXAuth = lib.mkForce false;

  fonts.fontconfig.enable = false;

}
