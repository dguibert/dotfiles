{ config, pkgs, lib, ... }:
rec {
  imports = [
    <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix>
    ../nixos/yubikey-gpg.nix
    ../nixos/distributed-build.nix
  ];
  services.xserver.videoDrivers = lib.mkForce [ "virtualbox" "modesetting" ];

  nixpkgs.overlays = [ (import ../pkgs-pinned-overlay.nix { system = nixpkgs.system; }) ];
  nixpkgs.config = {pkgs}: (import ~/.config/nixpkgs/config.nix { inherit pkgs; }) // {
    #packageOverrides.linuxPackages = boot.kernelPackages;
  };
  #nixpkgs.config = pkgs: (import ~/.nixpkgs/config.nix { inherit pkgs; }) // {
  #  xorg.fglrxCompat = true;
  #};
  environment.systemPackages = with pkgs; [
    vim vcsh gitFull pavucontrol
    gnupg
    gnupg1compat
    config.boot.kernelPackages.perf 
  ];
  programs.sysdig.enable = true;

  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = [ config.boot.kernelPackages.perf ];
  boot.supportedFilesystems = [ "zfs" ];
  #boot.zfs.enableUnstable = true;
  networking.hostId = "a8c01e02";

  #sudo mount -t vboxsf a629925  /a629925 -o uid=dguibert,gid=dguibert,fmask=111
  fileSystems."/a629925" = {
    fsType = "vboxsf";
    device = "a629925";
    options = [ "rw" "uid=dguibert" "gid=dguibert" "fmask=117" "dmask=007" ];
  };
  zramSwap.enable = true;
  swapDevices = [ { device = "/swapfile"; } ];
  systemd.tmpfiles.rules = [
    "D! /tmp 1777 root root"
    "d /tmp 1777 root root 10d"
  ];


  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioLight.override {
      /*gconf = gnome3.gconf;*/
      x11Support = true;
      /*gconfSupport = true;*/
      bluetoothSupport = true;
    };
  };
  services.tlp.enable = true;

  programs.bash.enableCompletion = true;
  environment.shellInit = ''
    export NIX_PATH=nixpkgs=https://github.com/dguibert/nixpkgs/archive/pu.tar.gz:nixos-config=$HOME/admin/nixops/$(hostname)/configuration.nix
  '';

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;
  services.openssh.ports = [22];
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
  users.users.root.openssh.authorizedKeys.keys = [
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
    ];

    #  boot.kernel.sysctl = {
    #    # enables syn flood protection
    #    "net.ipv4.tcp_syncookies" = "1";
    #
    #    # ignores source-routed packets
    #    "net.ipv4.conf.all.accept_source_route" = "0";
    #
    #    # ignores source-routed packets
    #    "net.ipv4.conf.default.accept_source_route" = "0";
    #
    #    # ignores ICMP redirects
    #    "net.ipv4.conf.all.accept_redirects" = "0";
    #
    #    # ignores ICMP redirects
    #    "net.ipv4.conf.default.accept_redirects" = "0";
    #
    #    # ignores ICMP redirects from non-GW hosts
    #    "net.ipv4.conf.all.secure_redirects" = "1";
    #
    #    # ignores ICMP redirects from non-GW hosts
    #    "net.ipv4.conf.default.secure_redirects" = "1";
    #
    #    # don't allow traffic between networks or act as a router
    #    "net.ipv4.ip_forward" = "0";
    #
    #    # don't allow traffic between networks or act as a router
    #    "net.ipv4.conf.all.send_redirects" = "0";
    #
    #    # don't allow traffic between networks or act as a router
    #    "net.ipv4.conf.default.send_redirects" = "0";
    #
    #    # reverse path filtering - IP spoofing protection
    #    "net.ipv4.conf.all.rp_filter" = "1";
    #
    #    # reverse path filtering - IP spoofing protection
    #    "net.ipv4.conf.default.rp_filter" = "1";
    #
    #    # ignores ICMP broadcasts to avoid participating in Smurf attacks
    #    "net.ipv4.icmp_echo_ignore_broadcasts" = "1";
    #
    #    # ignores bad ICMP errors
    #    "net.ipv4.icmp_ignore_bogus_error_responses" = "1";
    #
    #    # logs spoofed, source-routed, and redirect packets
    #    "net.ipv4.conf.all.log_martians" = "1";
    #
    #    # log spoofed, source-routed, and redirect packets
    #    "net.ipv4.conf.default.log_martians" = "1";
    #
    #    # implements RFC 1337 fix
    #    "net.ipv4.tcp_rfc1337" = "1";
    #  };

  
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "fr";
  services.xserver.xkbOptions = "eurosign:e";

  services.xserver.displayManager.auto.enable = true;
  services.xserver.displayManager.auto.user = "dguibert";

  # fonts
  fonts.enableFontDir = true;
  fonts.enableGhostscriptFonts = true;
  fonts.enableCoreFonts = true;
  fonts.fonts = with pkgs ; [ terminus_font powerline-fonts ];

  #X11 and Gnome3
  #services.xserver.desktopManager.default = "gnome3";
  #services.xserver.desktopManager.gnome3.enable = true;

  services.cntlm.enable = true;
  services.cntlm.username = "a629925";
  services.cntlm.domain = "ww930";
  services.cntlm.netbios_hostname = "fr-57nvj72";
  services.cntlm.proxy = [
    "10.89.0.72:84"
    #"proxy-emea.my-it-solutions.net:84"
    #"10.92.32.21:84"
    #"proxy-americas.my-it-solutions.net:84"
  ];
  services.cntlm.extraConfig = ''
NoProxy localhost, 127.0.0.*, 10.*, 192.168.*
  '';

  networking.interfaces.zt0.ipv4.addresses = [
            { address = "10.147.17.198"; prefixLength = 24; }
  ];
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.147.27.198/24" ];
    listenPort = 51821;
    privateKeyFile = "/etc/wireguard_key";
    peers = [
      { allowedIPs = [ "10.147.27.0/24" ];
        publicKey  = "wBBjx9LCPf4CQ07FKf6oR8S1+BoIBimu1amKbS8LWWo=";
        endpoint   = "83.155.85.77:500";
	persistentKeepalive = 25;
      }
      { allowedIPs = [ "10.147.27.198/32" ];
        publicKey  = "rbYanMKQBY/dteQYQsg807neESjgMP/oo+dkDsC5PWU=";
        endpoint   = "83.155.85.77:51821";
	persistentKeepalive = 25;
      }
      { allowedIPs = [ "10.147.27.123/32" ];
        publicKey  = "Z8yyrih3/vINo6XlEi4dC5i3wJCKjmmJM9aBr4kfZ1k=";
        endpoint   = "83.155.85.77:51820";
	persistentKeepalive = 25;
      }
    ];
  };
  networking.firewall.allowedUDPPorts = [ 51821 ];

  services.udev.packages = [ pkgs.android-udev-rules ];

  networking.firewall.checkReversePath = false;

  # (evince:16653): dconf-WARNING **: failed to commit changes to dconf:
  # GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name
  # ca.desrt.dconf was not provided by any .service files
  services.dbus.packages = with pkgs; [ gnome3.dconf ];

  virtualisation.docker.enable = true;
}
