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

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "fuse" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.perf ];
  nixpkgs.config.packageOverrides.linuxPackages = boot.kernelPackages;
  nixpkgs.config.allowUnfree = true;
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

  services.udev.extraRules = with pkgs; ''
    # This files changes the mode of the Dynastream ANT UsbStick2 so all users can read and write to it.
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fcf", ATTR{idProduct}=="1008", MODE="0666", SYMLINK+="ttyANT", ACTION=="add"
  '';

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
    myTexLive
    firefoxWrapper chromium
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

  programs.bash.enableCompletion = true;
  environment.shellInit = ''
    export NIX_PATH=nixpkgs=https://github.com/dguibert/nixpkgs/archive/pu.tar.gz:nixos-config=$HOME/admin/nixops/$(hostname)/configuration.nix
  '';

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;
  services.openssh.extraConfig = ''
    # https://zeitstrom.wordpress.com/2013/02/16/opensuse-sshd-server-x11-forwarding-fails-with-failed-to-allocate-internet-domain-x11-display-socket/
    AddressFamily inet
  '';
  programs.ssh.forwardX11 = true;
  programs.ssh.setXAuthLocation = true;
  users.users.root.openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAfi56MxrJRRWjj1myan0glpbXiPykZiU3qEzPZc4ijUY0VtGt4HQ7FTNUUHc+xtMqhAVgv2t9UNxkzcjmZjJqNHJ4ppsfJ4Ikam4Q8ENIvJJt4rz/Y6Z5nrMRtHmzNN0weg9R9PiYW5Bsh9epeCQzKl2R+IMTAaeqXf9vPf5uExps7/6xj1j0+KJNGpMB+VLYKAkCo6zg7NdSgA7Nt5AyfdB01snTP0YNf0vZb9v6/ns4cdJt7324/IyC/HlUV/IsnRSkiZBYJSqUSxCCpHfomUBXcnrMnkzb2LAOZBMATkS8qWyk/BXEEX3ENmkr4o8PPBEhvYjOOy3QGeriR69d dguibert@orsine" ];

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "fr,us";
  services.xserver.xkbOptions = "eurosign:e";

  services.xserver.resolutions = [{x=1440; y=900;}];
  services.xserver.videoDrivers = [ "intel" ];
  services.xserver.vaapiDrivers = [ pkgs.vaapiIntel ];

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  security.setuidPrograms = [ "su" "xlock" ];
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

  nix.useChroot = true;
  nix.extraOptions = "auto-optimise-store = true";
  nix.binaryCachePublicKeys = [
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
  ];

  # Enable ZeroTierOne
  services.zerotierone.enable = true;
  networking.firewall.allowedUDPPorts = [ 9993 ];

  # Virtualisation
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableHardening = false;

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "overlay";
  virtualisation.docker.socketActivation = true;
  systemd.sockets.docker.socketConfig.ListenStream = pkgs.lib.mkForce [ "0.0.0.0:2375" "/var/run/docker.sock" ];
  /*networking.firewall.allowedTCPPorts = [ 2375 ];*/
  /*virtualisation.docker.extraOptions = "-e lxc";*/
  /* FATA[0000] Error response from daemon: Cannot start container 237927be402d7427215cbabbfb12988d932d8c655e7ec39d0998e22664662685: fork/exec unshare: no such file or directory  */
  #systemd.network.networks."40-bond0".networkConfig.IPForward = true;
  #systemd.network.networks."40-docker0".networkConfig.IPForward = true;

  # ChromeCast ports
  # iptables -I INPUT -p udp -m udp --dport 32768:61000 -j ACCEPT
  networking.firewall.allowedUDPPortRanges = [ { from=32768; to=61000; } ];

}
