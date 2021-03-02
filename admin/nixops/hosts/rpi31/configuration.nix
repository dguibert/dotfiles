{ config, pkgs, lib, ... }:

with lib;
#let
#  nodes = import ../../modules/infra.nix;
#in

rec {
  #imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix> ];
  imports = [
    ../common.nix
    ../../modules/nix-conf.nix
    ../../modules/distributed-build.nix
    ../../users/rdolbeau
  ];

  #sdImage.bootSize = 512;

  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.generic-extlinux-compatible.configurationLimit = 10;

  boot.consoleLogLevel = lib.mkDefault 7;

  # The serial ports listed here are:
  # - ttyS0: for Tegra (Jetson TX1)
  # - ttyAMA0: for QEMU's -machine virt
  # Also increase the amount of CMA to ensure the virtual console on the RPi3 works.
  boot.kernelParams = ["cma=32M" "console=ttyS0,115200n8" "console=ttyAMA0,115200n8" "console=tty0"];

  boot.initrd.availableKernelModules = [
    # Allows early (earlier) modesetting for the Raspberry Pi
    "vc4" "bcm2835_dma" "i2c_bcm2835"
    # Allows early (earlier) modesetting for Allwinner SoCs
    "sun4i_drm" "sun8i_drm_hdmi" "sun8i_mixer"
  ];

  sdImage = {
    populateFirmwareCommands = let
      configTxt = pkgs.writeText "config.txt" ''
        kernel=u-boot-rpi3.bin

        # Boot in 64-bit mode.
        arm_control=0x200

        # U-Boot used to need this to work, regardless of whether UART is actually used or not.
        # TODO: check when/if this can be removed.
        enable_uart=1

        # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
        # when attempting to show low-voltage or overtemperature warnings.
        avoid_warnings=1
      '';
      in ''
        (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)
        cp ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin firmware/u-boot-rpi3.bin
        cp ${configTxt} firmware/config.txt
      '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };


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
    DHCP = "yes";
  };

  environment.noXlibs = true;
  programs.ssh.setXAuthLocation = false;
  security.pam.services.su.forwardXAuth = lib.mkForce false;

  fonts.fontconfig.enable = false;

  networking.firewall.allowedTCPPorts = [ config.services.sslh.port 22322 ];
  services.sslh = {
    enable=true;
    verbose=true;
    transparent=true;
    port=443;
    ##  { name: "openvpn"; host: "localhost"; port: "1194"; probe: "builtin"; },
    ##  { name: "xmpp"; host: "localhost"; port: "5222"; probe: "builtin"; },
    ##  { name: "http"; host: "localhost"; port: "80"; probe: "builtin"; },
    ##  { name: "tls"; host: "localhost"; port: "443"; probe: "builtin"; },
    appendConfig=''
      protocols:
      (
        { name: "ssh"; service: "ssh"; host: "localhost"; port: "22"; probe: "builtin"; },
        { name: "anyprot"; host: "localhost"; port: "${toString config.services.shadowsocks.port}"; probe: "builtin"; }
      );
    '';
  };
  ##services.haproxy.enable = true;
  ### https://datamakes.com/2018/02/17/high-intensity-port-sharing-with-haproxy/
  ##services.haproxy.config = ''
  ##  frontend ssl
  ##    mode tcp
  ##    bind 0.0.0.0:443
  ##    tcp-request inspect-delay 3s
  ##    tcp-request content accept if { req.ssl_hello_type 1 }

  ##    acl    ssh_payload        payload(0,7)    -m bin 5353482d322e30

  ##    use_backend openssh            if ssh_payload
  ##    use_backend openssh            if !{ req.ssl_hello_type 1 } { req.len 0 }
  ##    use_backend shadowsocks        if !{ req.ssl_hello_type 1 } !{ req.len 0 }

  ##  backend openssh
  ##    mode tcp
  ##    timeout server 3h
  ##    server openssh 127.0.0.1:22
  ##  backend shadowsocks
  ##    mode tcp
  ##    server socks 127.0.0.1:${toString config.services.shadowsocks.port}
  ##'';

  #systemd.services.sslh.serviceConfig.User=lib.mkForce "root";
  services.shadowsocks = {
    enable = true;
    localAddress= [ "127.0.0.1" ];
    port=8388;
    passwordFile = config.sops.secrets.shadowsocks.path;
  };

  # https://nixos.org/nixos/manual/index.html#module-services-weechat
  services.weechat.enable = true;
  # screen -x weechat/weechat-screen
  programs.screen.screenrc = ''
    multiuser on
    acladd dguibert
  '';
}
