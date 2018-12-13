{ config, pkgs, lib, ... }:

with lib;
#let
#  nodes = import <modules/infra.nix>;
#in

rec {
  #imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix> ];
  imports = [
    <nixpkgs/nixos/modules/profiles/minimal.nix>
    #../../profiles/installation-device.nix
    #./sd-image.nix
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
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEX3tOUaRwa9tVXn7GnU561QtklI6d+VuW/0vwoYiltk a0001 connect bot"
    ];

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

    nixpkgs.overlays = singleton (const (super: {
      dbus = super.dbus.override { x11Support = false; };
      networkmanager-fortisslvpn = super.networkmanager-fortisslvpn.override { withGnome = false; };
      networkmanager-l2tp = super.networkmanager-l2tp.override { withGnome = false; };
      networkmanager-openconnect = super.networkmanager-openconnect.override { withGnome = false; };
      networkmanager-openvpn = super.networkmanager-openvpn.override { withGnome = false; };
      networkmanager-vpnc = super.networkmanager-vpnc.override { withGnome = false; };
      networkmanager-iodine = super.networkmanager-iodine.override { withGnome = false; };
      pinentry = super.pinentry_ncurses;
      gobject-introspection = super.gobject-introspection.override { x11Support = false; };
    }));
}
