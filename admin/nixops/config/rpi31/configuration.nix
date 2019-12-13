{ config, pkgs, lib, ... }:

with lib;
#let
#  nodes = import ../../modules/infra.nix;
#in

rec {
  #imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix> ];
  imports = [
    ../../config/common.nix
    ../../modules/nix-conf.nix
    ../../modules/distributed-build.nix
    ../../config/users/dguibert
    ../../config/users/rdolbeau
  ];

  #sdImage.bootSize = 512;

  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.generic-extlinux-compatible.configurationLimit = 10;

  # !!! If your board is a Raspberry Pi 1, select this:
  #boot.kernelPackages = pkgs.linuxPackages_rpi;
  # !!! Otherwise (even if you have a Raspberry Pi 2 or 3), pick this:
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.supportedFilesystems = [ "zfs" ];
  boot.supportedFilesystems = mkForce [ /*"btrfs" "reiserfs"*/ "vfat" "f2fs" /*"xfs" "zfs"*/ "ntfs" /*"cifs"*/ ];
  #boot.zfs.enableUnstable = true;
  networking.hostId = "8425e349";
  networking.hostName = "rpi31";

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
  services.openssh.listenAddresses = [
    { addr = "127.0.0.1"; port=22; }
    { addr = "0.0.0.0"; port=22322; }
  ];

  environment.systemPackages = [ pkgs.vim ];

  nix.maxJobs = 4;

  networking.useNetworkd = lib.mkForce false;
  networking.dhcpcd.enable = false;
  systemd.network.networks."eth0" = {
    name = "eth0";
    DHCP = "both";
  };

  ## rpi31
  #networking.wireguard.interfaces.rpi31 = {
  #  ips = [
  #    "10.147.27.13/32"
  #    "fe80::216:3eff:fe14:bb31/64"
  #  ];
  #  listenPort = 500;
  #  allowedIPsAsRoutes=false;
  #  privateKeyFile = toString "/secrets/wireguard_key";
  #};
  # orsine
  networking.wireguard.interfaces.orsine = {
    ips = [
      "10.147.27.13/32"
      "fe80::216:3eff:fe07:ed74/64"
    ];
    listenPort = 501;
    allowedIPsAsRoutes=false;
    privateKeyFile = toString "/secrets/wireguard_key";
    peers = [
      { allowedIPs = [ "0.0.0.0/0" "ff02::/16" "::/0" ];
        publicKey  = "Z8yyrih3/vINo6XlEi4dC5i3wJCKjmmJM9aBr4kfZ1k=";
        endpoint   = "192.168.1.32:500";
        persistentKeepalive = 25;
      }
    ];
  };
  # vbox-54nj72
  networking.wireguard.interfaces.vbox-54nvj72 = {
    ips = [
      "10.147.27.13/32"
      "fe80::216:3eff:fe1c:82d3/64"
    ];
    listenPort = 502;
    allowedIPsAsRoutes=false;
    privateKeyFile = toString "/secrets/wireguard_key";
    peers = [
      { allowedIPs = [ "0.0.0.0/0" "ff02::/16" "::/0" ];
        publicKey  = "rbYanMKQBY/dteQYQsg807neESjgMP/oo+dkDsC5PWU=";
        #endpoint   = "orsin.freeboxos.fr:500";
        persistentKeepalive = 25;
      }
    ];
  };
  # titan
  networking.wireguard.interfaces.titan = {
    ips = [
      "10.147.27.13/32"
      "fe80::216:3eff:fe6a:481f/64"
    ];
    listenPort = 503;
    allowedIPsAsRoutes=false;
    privateKeyFile = toString "/secrets/wireguard_key";
    peers = [
      { allowedIPs = [ "0.0.0.0/0" "ff02::/16" "::/0" ];
        publicKey  = "wJPL+85/cCK53thEzXB9LIrXF9tCVZ8kxK+tDCHaAU0=";
        endpoint   = "192.168.1.24:500";
      }
    ];
  };
  # oneplus1
  networking.wireguard.interfaces.oneplus1 = {
    ips = [
      "10.147.27.13/32"
      "fe80::216:3eff:fe09:495d/64"
    ];
    listenPort = 504;
    allowedIPsAsRoutes=false;
    privateKeyFile = toString "/secrets/wireguard_key";
    peers = [
      { allowedIPs = [ "0.0.0.0/0" "ff02::/16" "::/0" ];
        publicKey  = "MkVk/+vE2kNw8Pi5UljJifp0esCBxztPwQ7AFNMkkW4=";
        persistentKeepalive = 25;
      }
    ];
  };
  networking.firewall.allowedUDPPorts = [ 9993 500 501 502 503 504 6696 ];
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = "1";
    "net.ipv6.conf.all.forwarding"="1";
  };
  services.babeld.enable = true;
  services.babeld.interfaceDefaults = {
    type = "tunnel";
    "split-horizon" = true;
  };
  services.babeld.extraConfig = ''
    interface orsine
    interface titan
    interface rpi31
    interface vbox-54nvj72
    # mesh IPv4
    redistribute local ip 10.147.27.0/24 metric 128
    redistribute ip 10.147.27.0/24 ge 13 metric 128
    ## refuse anything else not explicitely allowed
    redistribute local deny
    redistribute deny
  '';


  environment.noXlibs = true;
  programs.ssh.setXAuthLocation = false;
  security.pam.services.su.forwardXAuth = lib.mkForce false;

  fonts.fontconfig.enable = false;

  networking.firewall.allowedTCPPorts = [ config.services.sslh.port 22322 ];
  services.sslh = {
    enable=true;
    verbose=true;
    #transparent=true;
    #port=443;
    ##  { name: "openvpn"; host: "localhost"; port: "1194"; probe: "builtin"; },
    ##  { name: "xmpp"; host: "localhost"; port: "5222"; probe: "builtin"; },
    ##  { name: "http"; host: "localhost"; port: "80"; probe: "builtin"; },
    ##  { name: "ssl"; host: "localhost"; port: "443"; probe: "builtin"; },
    appendConfig=''
      protocols:
      (
        { name: "ssh"; service: "ssh"; host: "localhost"; port: "22"; probe: "builtin"; },
        { name: "anyprot"; host: "localhost"; port: "8388"; probe: "builtin"; }
      );
    '';
  };

  #systemd.services.sslh.serviceConfig.User=lib.mkForce "root";
  services.shadowsocks = {
    enable = true;
    localAddress= [ "127.0.0.1" ];
    #port=443;
    passwordFile = "/secrets/shadowsocks";
  };
}
