{ config, pkgs, lib, ... }:

with lib;
#let
#  nodes = import ../../modules/infra.nix;
#in

rec {
  #imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix> ];
  imports = [
    ../common.nix
    ../../users/rdolbeau
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
  boot.kernelPackages = pkgs.linuxPackages_5_15;
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

  networking.firewall.allowedTCPPorts = [ 443 22322 2222 ];
  networking.firewall.extraCommands = ''
    ip46tables -t mangle -F DIVERT 2> /dev/null || true
    ip46tables -t mangle -X DIVERT 2> /dev/null || true
    ip46tables -t mangle -N DIVERT 2> /dev/null || true
    ip46tables -t mangle -F PREROUTING -j DIVERT 2> /dev/null || true
    ip46tables -t mangle -X PREROUTING -j DIVERT 2> /dev/null || true
    ip46tables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT
    ip46tables -t mangle -A DIVERT -j MARK --set-mark 111
    ip46tables -t mangle -A DIVERT -j ACCEPT
    ${pkgs.iproute2}/bin/ip rule add fwmark 111 lookup 100
    ${pkgs.iproute2}/bin/ip route add local 0.0.0.0/0 dev lo table 100

    #echo 1 > /proc/sys/net/ipv4/conf/all/forwarding
    #echo 1 > /proc/sys/net/ipv4/conf/all/send_redirects
    #echo 1 > /proc/sys/net/ipv4/conf/bond0/send_redirects
  '';
  #networking.firewall.allowedTCPPorts = [ config.services.sslh.port 22322 ];
  #services.sslh = {
  #  enable=true;
  #  verbose=true;
  #  transparent=true;
  #  port=443;
  #  ##  { name: "openvpn"; host: "localhost"; port: "1194"; probe: "builtin"; },
  #  ##  { name: "xmpp"; host: "localhost"; port: "5222"; probe: "builtin"; },
  #  ##  { name: "http"; host: "localhost"; port: "80"; probe: "builtin"; },
  #  ##  { name: "tls"; host: "localhost"; port: "443"; probe: "builtin"; },
  #  appendConfig=''
  #    protocols:
  #    (
  #      { name: "ssh"; service: "ssh"; host: "localhost"; port: "22"; probe: "builtin"; },
  #      { name: "anyprot"; host: "localhost"; port: "${toString config.services.shadowsocks.port}"; probe: "builtin"; }
  #    );
  #  '';
  #};
  services.haproxy.enable = true;
  ### https://datamakes.com/2018/02/17/high-intensity-port-sharing-with-haproxy/
  services.haproxy.config = ''
    defaults
      log  global
      mode tcp
      timeout connect 10s
      timeout client 36h
      timeout server 36h
    global
      log /dev/log  local0 debug

    frontend ssl
      mode tcp
      log global
      option tcplog
      bind 0.0.0.0:443
      tcp-request inspect-delay 3s
      tcp-request content accept if { req.ssl_hello_type 1 }

      acl    ssh_payload        payload(0,7)    -m bin 5353482d322e30
      #acl valid_payload req.payload(0,7) -m str "SSH-2.0"
      #tcp-request content reject if !valid_payload
      #tcp-request content accept if { req_ssl_hello_type 1 }

      use_backend openssh            if ssh_payload
      use_backend openssh            if !{ req.ssl_hello_type 1 } { req.len 0 }
      use_backend shadowsocks        if !{ req.ssl_hello_type 1 } !{ req.len 0 }

    backend openssh
      mode tcp
      server openssh 127.0.0.1:22
    backend shadowsocks
      mode tcp
      server socks 127.0.0.1:${toString config.services.shadowsocks.port}

    frontend ssl_t
      mode tcp
      log global
      option tcplog
      bind 0.0.0.0:4443
      tcp-request inspect-delay 3s
      tcp-request content accept if { req.ssl_hello_type 1 }

      acl    ssh_payload        payload(0,7)    -m bin 5353482d322e30

      use_backend openssh_t          if ssh_payload
      use_backend openssh_t          if !{ req.ssl_hello_type 1 } { req.len 0 }
      use_backend shadowsocks        if !{ req.ssl_hello_type 1 } !{ req.len 0 }

    frontend ssh_t
      mode tcp
      bind 0.0.0.0:2222 transparent
    backend openssh_t
      mode tcp
      source 0.0.0.0 usesrc clientip
      server openssh 127.0.0.1:22
  '';
  # https://www.nginx.com/blog/running-non-ssl-protocols-over-ssl-port-nginx-1-15-2/
  #services.nginx.enable = true;
  #services.nginx.streamConfig = ''
  #  upstream ssh {
  #    server 127.0.0.1:22;
  #  }

  #  upstream shadowsocks {
  #    server 127.0.0.1:${toString config.services.shadowsocks.port};
  #  }

  #  map $ssl_preread_protocol $upstream {
  #    "" ssh;
  #    "TLSv1*"   shadowsocks;
  #    default    shadowsocks;
  #  }

  #  # SSH and SSL on the same port
  #  server {
  #    listen 443;

  #    proxy_pass $upstream;
  #    ssl_preread on;
  #  }
  #'';

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
