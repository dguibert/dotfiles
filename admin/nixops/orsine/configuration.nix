####{ config, nodes, pkgs, lib, ...}@attrs:
####with lib;
####rec {
####  imports = [
####    ./orsine/configuration.nix
####    ./common.nix
####  ] ++ (import ../services/service-list.nix) { attr = "orsine"; } attrs;
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

rec {

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.device = "/dev/disk/by-id/ata-Samsung_SSD_840_PRO_Series_S12PNEAD231035B";
  boot.kernelParams = ["resume=/dev/disk/by-id/ata-Samsung_SSD_840_PRO_Series_S12PNEAD231035B-part2" ];
  boot.loader.grub.configurationLimit = 10;

  boot.kernelPackages = pkgs.linuxPackages_4_12;
  boot.kernelModules = [ "fuse" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.perf ];
  nixpkgs.config = {pkgs}: (import ~/.config/nixpkgs/config.nix { inherit pkgs; }) // {
    packageOverrides.linuxPackages = boot.kernelPackages;
  };
  boot.supportedFilesystems = [ "zfs" ];

  networking.hostId = "a8c00e01";

  networking.hostName = "orsine"; # Define your hostname.
  networking.useNetworkd = true;

  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.wireless.interfaces = [ "wls1" ];
  networking.wireless.driver = "nl80211";
  networking.wireless.userControlled.enable = true;

#  networking.bridges.br0.interfaces = [ "bond0" ];
#  networking.interfaces.bond0.ip4 = lib.mkOverride 0 [ ];
  networking.bonds.bond0.interfaces = [ "enp0s25" "wls1" ];
  networking.interfaces.enp0s25.ip4 = lib.mkOverride 0 [ ];
  networking.interfaces.wls1.ip4 = lib.mkOverride 0 [ ];
  boot.extraModprobeConfig=''
    options bonding mode=active-backup miimon=100 primary=enp0s25
  '';

  hardware.bluetooth.enable = true;

  hardware.opengl.driSupport32Bit = true;

  services.logind.extraConfig = "LidSwitchIgnoreInhibited=no";

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

  # Select internationalisation properties.
  i18n = {
     consoleFont = "Lat2-Terminus16";
     consoleKeyMap = "fr";
     defaultLocale = "en_US.UTF-8";
   };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; let
      myTexLive = texlive.combine {
        inherit (texlive) scheme-small beamer pgf algorithms cm-super;
      };
    in [
    vim htop lsof
    wget telnet
    bc
    subversion mercurial unison monotone git darcs
    gnuplot graphviz imagemagick
    diffstat diffutils binutils zip unzip
    unrar cabextract cpio p7zip lzma which file
    acpitool iputils
    fuse sshfsFuse
    manpages gnupg tree
# lsof - shows open files/sockets, including network
    lsof
    vim ethtool
    wirelesstools wpa_supplicant_gui
    dmenu xlockmore xss-lock slock xorg.xset xorg.xinput xorg.xsetroot xorg.setxkbmap xorg.xmodmap
    evince #calibre
    mplayer gst_all.gstreamer
    alsaPlugins pavucontrol

    nixops
    config.boot.kernelPackages.perf 
  ] ++ (with aspellDicts; [en fr]) ++ [
    rxvt_unicode
  ];
  programs.browserpass.enable = true;

  programs.bash.enableCompletion = true;
  environment.shellInit = ''
    export NIX_PATH=nixpkgs=https://github.com/dguibert/nixpkgs/archive/pu.tar.gz:nixos-config=$HOME/admin/nixops/$(hostname)/configuration.nix
  '';

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;
  services.openssh.ports = [22322];
  services.openssh.passwordAuthentication = false;
  services.openssh.hostKeys = [
            { type = "rsa"; bits = 4096; path = "/etc/ssh/ssh_host_rsa_key"; }
            { type = "ed25519"; path = "/etc/ssh/ssh_host_ed25519_key"; }
	  ];
  services.openssh.extraConfig = ''
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
    MACs umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
  '';
  # https://www.sweharris.org/post/2016-10-30-ssh-certs/
  # http://www.lorier.net/docs/ssh-ca
  # https://linux-audit.com/granting-temporary-access-to-servers-using-signed-ssh-keys/
  users.users.root.openssh.authorizedKeys.keys = [
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHj9CvDWTyCZZnIhq7Gq15a/iDZzFYmcTV8MCb+G/KY44j0gVVpOa7U+LL0HqCyx+nKhx83HGpC7rFq62wQOTVHisws68XlvBqU2XswWvAZqGP1gvtV1P3OMMWxUZ2COIKBJ7a1tzbhOdOtNEaLusl5htOqFigyxhGT+ngkDqJC3M4lF2ayjoGxRvAn88t5kL3yftFwOKvBm6ALEXRwYPqCWJ761J2ML8J/VdUa1OjPd3HXS2r4y4QBxh7eopQrlsQ2xWqH8harP8kTjYPcEgWeRpKl/h7Dzkgxw8G3WMJnob1s5kRdI1LlxhxOZMCMJfpmctY4d70LMuDL/I6haB5 user_ca"
    ];
  users.users.dguibert.openssh.authorizedKeys.keys = [
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHj9CvDWTyCZZnIhq7Gq15a/iDZzFYmcTV8MCb+G/KY44j0gVVpOa7U+LL0HqCyx+nKhx83HGpC7rFq62wQOTVHisws68XlvBqU2XswWvAZqGP1gvtV1P3OMMWxUZ2COIKBJ7a1tzbhOdOtNEaLusl5htOqFigyxhGT+ngkDqJC3M4lF2ayjoGxRvAn88t5kL3yftFwOKvBm6ALEXRwYPqCWJ761J2ML8J/VdUa1OjPd3HXS2r4y4QBxh7eopQrlsQ2xWqH8harP8kTjYPcEgWeRpKl/h7Dzkgxw8G3WMJnob1s5kRdI1LlxhxOZMCMJfpmctY4d70LMuDL/I6haB5 user_ca"
    "cert-authority ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGFz6l5s57+UjjX72iTea17I+qfHWPntFrM0rzYbr+fUBZd0SR2dKnz+nSaBhDtCvD5N+YOWwXEK4WvQ0PkT5Qk= bguibertd@genji0"
    ];

  boot.kernel.sysctl = {
    # enables syn flood protection
    "net.ipv4.tcp_syncookies" = "1";

    # ignores source-routed packets
    "net.ipv4.conf.all.accept_source_route" = "0";

    # ignores source-routed packets
    "net.ipv4.conf.default.accept_source_route" = "0";

    # ignores ICMP redirects
    "net.ipv4.conf.all.accept_redirects" = "0";

    # ignores ICMP redirects
    "net.ipv4.conf.default.accept_redirects" = "0";

    # ignores ICMP redirects from non-GW hosts
    "net.ipv4.conf.all.secure_redirects" = "1";

    # ignores ICMP redirects from non-GW hosts
    "net.ipv4.conf.default.secure_redirects" = "1";

    # don't allow traffic between networks or act as a router
    "net.ipv4.ip_forward" = "0";

    # don't allow traffic between networks or act as a router
    "net.ipv4.conf.all.send_redirects" = "0";

    # don't allow traffic between networks or act as a router
    "net.ipv4.conf.default.send_redirects" = "0";

    # reverse path filtering - IP spoofing protection
    "net.ipv4.conf.all.rp_filter" = "1";

    # reverse path filtering - IP spoofing protection
    "net.ipv4.conf.default.rp_filter" = "1";

    # ignores ICMP broadcasts to avoid participating in Smurf attacks
    "net.ipv4.icmp_echo_ignore_broadcasts" = "1";

    # ignores bad ICMP errors
    "net.ipv4.icmp_ignore_bogus_error_responses" = "1";

    # logs spoofed, source-routed, and redirect packets
    "net.ipv4.conf.all.log_martians" = "1";

    # log spoofed, source-routed, and redirect packets
    "net.ipv4.conf.default.log_martians" = "1";

    # implements RFC 1337 fix
    "net.ipv4.tcp_rfc1337" = "1";
  };


  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "fr";
  services.xserver.xkbOptions = "eurosign:e";

  services.xserver.resolutions = [{x=1440; y=900;}];
  services.xserver.videoDrivers = [ "intel" "displaylink" ];
  hardware.opengl.extraPackages = [ pkgs.vaapiIntel ];

#  services.xserver.desktopManager.default = "gnome3";
#  services.xserver.desktopManager.gnome3.enable = true;
#  networking.wireless.enable = mkForce false; # - You can not use networking.networkmanager with services.networking.wireless
  services.xserver.displayManager.auto.enable = true;
  services.xserver.displayManager.auto.user = "dguibert";

  fonts.enableFontDir = true;
  fonts.enableGhostscriptFonts = true;
  fonts.enableCoreFonts = true;
  fonts.fonts = with pkgs ; [ terminus_font powerline-fonts ];

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.kdm.enable = true;
  # services.xserver.desktopManager.kde4.enable = true;

  security.wrappers.xlock.source = "${pkgs.xlockmore}/bin/xlock";

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  fileSystems = [
  { mountPoint = "/tmp"; device="tmpfs"; options= [ "defaults" "noatime" "mode=1777" "size=3G" ]; fsType="tmpfs"; }
  ];
  systemd.tmpfiles.rules = [
    "D! /tmp 1777 root root"
    "d /tmp 1777 root root 10d"
  ];

  zramSwap.enable = true;

  nix.useSandbox = true;
  nix.extraOptions = "auto-optimise-store = true";
  nix.binaryCachePublicKeys = [
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
  ];

  # Enable ZeroTierOne
  services.zerotierone.enable = true;

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.147.27.123/24" ];
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard_key";
    peers = [
      { allowedIPs = [ "10.147.27.0/24" ];
        publicKey  = "rbYanMKQBY/dteQYQsg807neESjgMP/oo+dkDsC5PWU=";
        endpoint   = "orsin.freeboxos.fr:51821";
	persistentKeepalive = 25;
      }
    ];
  };
  networking.firewall.allowedUDPPorts = [ 9993 51820 ];

  # Virtualisation
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableHardening = false;

  virtualisation.docker.enable = true;
  #virtualisation.docker.storageDriver = "overlay";
  #systemd.sockets.docker.socketConfig.ListenStream = pkgs.lib.mkForce [ "0.0.0.0:2375" "/var/run/docker.sock" ];
  /*networking.firewall.allowedTCPPorts = [ 2375 ];*/
  /*virtualisation.docker.extraOptions = "-e lxc";*/
  /* FATA[0000] Error response from daemon: Cannot start container 237927be402d7427215cbabbfb12988d932d8c655e7ec39d0998e22664662685: fork/exec unshare: no such file or directory  */
  #systemd.network.networks."40-bond0".networkConfig.IPForward = true;
  #systemd.network.networks."40-docker0".networkConfig.IPForward = true;
  virtualisation.docker.liveRestore = false;

  services.udev.extraRules = with pkgs; ''
	  # 80ee:0021
	  SUBSYSTEM=="usb",ATTR{idVendor}=="[80ee]", MODE="0660", GROUP="users"
	  SUBSYSTEM=="usb",ATTR{idVendor}=="[18d1]", MODE="0660", GROUP="users" # Bus 001 Device 016: ID 18d1:d00d Google Inc.
	  SUBSYSTEM=="usb",ATTR{idVendor}=="[80ee]",ATTR{idProduct}=="[0021]",SYMLINK+="android_adb"
	  SUBSYSTEM=="usb",ATTR{idVendor}=="[80ee]",ATTR{idProduct}=="[0021]",SYMLINK+="android_fastboot"
          # This files changes the mode of the Dynastream ANT UsbStick2 so all users can read and write to it.
          SUBSYSTEM=="usb", ATTR{idVendor}=="0fcf", ATTR{idProduct}=="1008", MODE="0666", SYMLINK+="ttyANT", ACTION=="add"
  '';

  #virtualisation.libvirtd.enable = true;
  networking.firewall.checkReversePath = false;

  # ChromeCast ports
  # iptables -I INPUT -p udp -m udp --dport 32768:61000 -j ACCEPT
  networking.firewall.allowedUDPPortRanges = [ { from=32768; to=61000; } ];

  # (evince:16653): dconf-WARNING **: failed to commit changes to dconf:
  # GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name
  # ca.desrt.dconf was not provided by any .service files
  services.dbus.packages = with pkgs; [ gnome3.dconf ];
}
