{ config, pkgs, lib, ... }:

{
  #imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix> ];
  imports = [
    <nixpkgs/nixos/modules/profiles/base.nix>
    #../../profiles/installation-device.nix
    #./sd-image.nix
    ../nixos/distributed-build.nix
  ];

  nixpkgs.system = "aarch64-linux";
  assertions = lib.singleton {
    assertion = pkgs.stdenv.system == "aarch64-linux";
    message = "sd-image-aarch64.nix can be only built natively on Aarch64 / ARM64; " +
      "it cannot be cross compiled";
  };

  # Needed by RPi firmware
  nixpkgs.config.allowUnfree = true;
  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # !!! If your board is a Raspberry Pi 1, select this:
  #boot.kernelPackages = pkgs.linuxPackages_rpi;
  # !!! Otherwise (even if you have a Raspberry Pi 2 or 3), pick this:
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "zfs" ];
  #boot.zfs.enableUnstable = true; #error: Package ‘spl-kernel-0.7.3-4.14’
  networking.hostId = "8425e349";

  # !!! This is only for ARMv6 / ARMv7. Don't enable this on AArch64, cache.nixos.org works there.
  #nix.binaryCaches = lib.mkForce [ "http://nixos-arm.dezgeg.me/channel" ];
  #nix.binaryCachePublicKeys = [ "nixos-arm.dezgeg.me-1:xBaUKS3n17BZPKeyxL4JfbTqECsT+ysbDJz29kLFRW0=%" ];

  # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
  boot.kernelParams = ["cma=32M" "console=ttyS0,115200n8" "console=ttyAMA0,115200n8" "console=tty0"];

  # File systems configuration for using the installer's partition layout
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  # !!! Adding a swap file is optional, but strongly recommended!
  swapDevices = [ { device = "/swapfile"; size = 1024; } ];

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n = {
     consoleFont = "Lat2-Terminus16";
     consoleKeyMap = "fr";
     defaultLocale = "en_US.UTF-8";
   };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;
  services.openssh.ports = [22322 443 ];
  services.openssh.passwordAuthentication = false;
  services.openssh.hostKeys = [
            { type = "rsa"; bits = 4096; path = "/etc/ssh/ssh_host_rsa_key"; }
            { type = "ed25519"; path = "/etc/ssh/ssh_host_ed25519_key"; }
	  ];
  services.openssh.extraConfig = ''
    Ciphers chacha20-poly1305@openssh.com,aes256-cbc,aes256-gcm@openssh.com,aes256-ctr
    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
    MACs umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
  '';
  # https://www.sweharris.org/post/2016-10-30-ssh-certs/
  # http://www.lorier.net/docs/ssh-ca
  # https://linux-audit.com/granting-temporary-access-to-servers-using-signed-ssh-keys/
  users.users.root.openssh.authorizedKeys.keys = [
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHj9CvDWTyCZZnIhq7Gq15a/iDZzFYmcTV8MCb+G/KY44j0gVVpOa7U+LL0HqCyx+nKhx83HGpC7rFq62wQOTVHisws68XlvBqU2XswWvAZqGP1gvtV1P3OMMWxUZ2COIKBJ7a1tzbhOdOtNEaLusl5htOqFigyxhGT+ngkDqJC3M4lF2ayjoGxRvAn88t5kL3yftFwOKvBm6ALEXRwYPqCWJ761J2ML8J/VdUa1OjPd3HXS2r4y4QBxh7eopQrlsQ2xWqH8harP8kTjYPcEgWeRpKl/h7Dzkgxw8G3WMJnob1s5kRdI1LlxhxOZMCMJfpmctY4d70LMuDL/I6haB5 user_ca"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEX3tOUaRwa9tVXn7GnU561QtklI6d+VuW/0vwoYiltk a0001 connect bot"
    ];

  environment.systemPackages = [ pkgs.vim ];

  nix.maxJobs = 4;

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.147.27.13/24" ];
    listenPort = 500;
    privateKeyFile = "/etc/wireguard_key";
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

}
