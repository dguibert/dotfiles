{ config, pkgs, lib, ... }:
rec {
  imports = [
    <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix>
    ../nixos/yubikey-gpg.nix
    ../nixos/distributed-build.nix
  ];
  services.xserver.videoDrivers = lib.mkForce [ "virtualbox" "modesetting" ];

  i18n.consoleKeyMap="fr";

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
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHj9CvDWTyCZZnIhq7Gq15a/iDZzFYmcTV8MCb+G/KY44j0gVVpOa7U+LL0HqCyx+nKhx83HGpC7rFq62wQOTVHisws68XlvBqU2XswWvAZqGP1gvtV1P3OMMWxUZ2COIKBJ7a1tzbhOdOtNEaLusl5htOqFigyxhGT+ngkDqJC3M4lF2ayjoGxRvAn88t5kL3yftFwOKvBm6ALEXRwYPqCWJ761J2ML8J/VdUa1OjPd3HXS2r4y4QBxh7eopQrlsQ2xWqH8harP8kTjYPcEgWeRpKl/h7Dzkgxw8G3WMJnob1s5kRdI1LlxhxOZMCMJfpmctY4d70LMuDL/I6haB5 user_ca"
    ];
  users.users.dguibert.openssh.authorizedKeys.keys = [
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHj9CvDWTyCZZnIhq7Gq15a/iDZzFYmcTV8MCb+G/KY44j0gVVpOa7U+LL0HqCyx+nKhx83HGpC7rFq62wQOTVHisws68XlvBqU2XswWvAZqGP1gvtV1P3OMMWxUZ2COIKBJ7a1tzbhOdOtNEaLusl5htOqFigyxhGT+ngkDqJC3M4lF2ayjoGxRvAn88t5kL3yftFwOKvBm6ALEXRwYPqCWJ761J2ML8J/VdUa1OjPd3HXS2r4y4QBxh7eopQrlsQ2xWqH8harP8kTjYPcEgWeRpKl/h7Dzkgxw8G3WMJnob1s5kRdI1LlxhxOZMCMJfpmctY4d70LMuDL/I6haB5 user_ca"
    "cert-authority ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGFz6l5s57+UjjX72iTea17I+qfHWPntFrM0rzYbr+fUBZd0SR2dKnz+nSaBhDtCvD5N+YOWwXEK4WvQ0PkT5Qk= bguibertd@genji0"
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

  
  # Set your time zone.
  time.timeZone = "Europe/Paris";

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

  nix.useSandbox = true;
  nix.extraOptions = ''
    auto-optimise-store = true
    plugin-files = ${pkgs.nix-plugins.override { nix = config.nix.package; }}/lib/nix/plugins/libnix-extra-builtins.so
  '';
  nix.binaryCachePublicKeys = [
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
  ];

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
  networking.firewall.allowedUDPPorts = [ 51821 ];

  services.udev.packages = [ pkgs.android-udev-rules ];

  networking.firewall.checkReversePath = false;

  # (evince:16653): dconf-WARNING **: failed to commit changes to dconf:
  # GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name
  # ca.desrt.dconf was not provided by any .service files
  services.dbus.packages = with pkgs; [ gnome3.dconf ];
}
