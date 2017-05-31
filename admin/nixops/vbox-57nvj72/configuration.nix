{ config, pkgs, lib, ... }:
{
  imports = [ <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix> ];
  services.xserver.videoDrivers = lib.mkForce [ "virtualbox" "modesetting" ];

  i18n.consoleKeyMap="fr";

  nixpkgs.config = import ~/.nixpkgs/config.nix;
  #nixpkgs.config = pkgs: (import ~/.nixpkgs/config.nix { inherit pkgs; }) // {
  #  xorg.fglrxCompat = true;
  #};
  environment.systemPackages = with pkgs; [
    vim vcsh gitFull pavucontrol
    gnupg
    gnupg1compat
    config.boot.kernelPackages.perf 
  ];

  boot.kernelPackages = pkgs.linuxPackages_4_9;
  boot.extraModulePackages = [ config.boot.kernelPackages.perf ];
  boot.supportedFilesystems = [ "zfs" ];
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
            { type = "ed25519"; path = "/etc/ssh/ssh_host_ed25519_key"; }
	  ];
  services.openssh.extraConfig = ''
    Ciphers chacha20-poly1305@openssh.com
    KexAlgorithms curve25519-sha256@libssh.org
    MACs umac-128-etm@openssh.com
  '';
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

  
  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "fr,us";
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
  nix.extraOptions = "auto-optimise-store = true";
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

  virtualisation.docker.enable = true;
  virtualisation.docker.liveRestore = false;

  services.udev.extraRules = with pkgs; ''
	  # 80ee:0021
	  SUBSYSTEM=="usb",ATTR{idVendor}=="[80ee]", MODE="0660", GROUP="users"
	  SUBSYSTEM=="usb",ATTR{idVendor}=="[18d1]", MODE="0660", GROUP="users" # Bus 001 Device 016: ID 18d1:d00d Google Inc.
	  SUBSYSTEM=="usb",ATTR{idVendor}=="[80ee]",ATTR{idProduct}=="[0021]",SYMLINK+="android_adb"
	  SUBSYSTEM=="usb",ATTR{idVendor}=="[80ee]",ATTR{idProduct}=="[0021]",SYMLINK+="android_fastboot"
  '';

  virtualisation.libvirtd.enable = true;
  networking.firewall.checkReversePath = false;

  # (evince:16653): dconf-WARNING **: failed to commit changes to dconf:
  # GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name
  # ca.desrt.dconf was not provided by any .service files
  services.dbus.packages = with pkgs; [ gnome3.dconf ];
}
