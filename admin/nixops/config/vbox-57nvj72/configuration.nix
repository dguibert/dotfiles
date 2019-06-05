{ config, pkgs, lib, ... }:
rec {
  imports = [
    <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix>
    ../../config/common.nix
    ../../config/users/dguibert
    ../../modules/yubikey-gpg.nix
    ../../modules/distributed-build.nix
    ../../modules/nix-conf.nix
    #<home-manager/nixos>
  ];
  #home-manager.users.dguibert = (import ../users/dguibert/home.nix {}).withoutX11 { inherit config pkgs lib; };
  #home-manager.users.root = (import ../users/root/home.nix {}).home { inherit pkgs lib; };
  #services.xserver.videoDrivers = lib.mkForce [ "virtualbox" "modesetting" ];

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
  networking.hostName = "vbox-57nvj72";

  #sudo mount -t vboxsf a629925  /a629925 -o uid=dguibert,gid=dguibert,fmask=111
  #fileSystems."/a629925" = {
  #  fsType = "vboxsf";
  #  device = "a629925";
  #  options = [ "rw" "uid=dguibert" "gid=dguibert" "fmask=117" "dmask=007" ];
  #};
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
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
  services.openssh.ports = [22];

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
  #services.xserver.displayManager.lightdm.enable = true;
  #services.xserver.desktopManager.pantheon.enable = true;

  # fonts
  fonts.enableFontDir = true;
  fonts.enableGhostscriptFonts = true;
  fonts.enableCoreFonts = true;
  fonts.fonts = with pkgs ; [ terminus_font powerline-fonts ];

  #X11 and Gnome3
  #services.xserver.desktopManager.default = "xfce";
  #services.xserver.desktopManager.xfce.enable = true;
  #services.xserver.desktopManager.gnome3.enable = true;

  # sudo /run/current-system/fine-tune/child-1/bin/switch-to-configuration test
  nesting.clone = [
    {
      boot.loader.grub.configurationName = "Work";
      networking.proxy.default = "http://localhost:3128";
      networking.proxy.noProxy = "127.0.0.1,localhost,10.*,192.168.*";
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

    }
  ];

  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
    "" # clear old command
    "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --ignore docker0"
  ];
  # rpi31
  networking.wireguard.interfaces.rpi31 = {
    ips = [
      "fe80::216:3eff:fe0c:6b11/64"
    ];
    listenPort = 500;
    allowedIPsAsRoutes=false;
    privateKeyFile = toString <secrets/wireguard_key>;
    peers = [
      { allowedIPs = [ "10.147.27.0/24" "::/0" ];
        publicKey  = "wBBjx9LCPf4CQ07FKf6oR8S1+BoIBimu1amKbS8LWWo=";
        endpoint   = "orsin.freeboxos.fr:502";
        persistentKeepalive = 25;
      }
    ];
  };
  # orsine
  networking.wireguard.interfaces.orsine = {
    ips = [
      "fe80::216:3eff:fe34:aa1b/64"
    ];
    listenPort = 501;
    allowedIPsAsRoutes=false;
    privateKeyFile = toString <secrets/wireguard_key>;
    peers = [
      { allowedIPs = [ "10.147.27.0/24" "::/0" ];
        publicKey  = "Z8yyrih3/vINo6XlEi4dC5i3wJCKjmmJM9aBr4kfZ1k=";
        endpoint   = "192.168.1.32:502";
	      persistentKeepalive = 25;
      }
    ];
  };
  # vbox-54nj72
  networking.wireguard.interfaces.vbox-54nvj72 = {
    ips = [
      "10.147.27.198/24"
      "fe80::216:3eff:fe24:c117/64"
    ];
    listenPort = 502;
    allowedIPsAsRoutes=false;
    privateKeyFile = toString <secrets/wireguard_key>;
  };
  # titan
  networking.wireguard.interfaces.titan = {
    ips = [
      "fe80::216:3eff:fe06:e0b6/64"
    ];
    listenPort = 503;
    allowedIPsAsRoutes=false;
    privateKeyFile = toString <secrets/wireguard_key>;
    peers = [
      { allowedIPs = [ "10.147.27.0/24" "::/0" ];
        publicKey  = "wJPL+85/cCK53thEzXB9LIrXF9tCVZ8kxK+tDCHaAU0=";
        endpoint   = "192.168.1.24:502";
	#persistentKeepalive = 25;
      }
    ];
  };
  networking.firewall.allowedUDPPorts = [ 9993 500 501 502 503 ];


  services.udev.packages = [ pkgs.android-udev-rules ];

  networking.firewall.checkReversePath = false;

  # (evince:16653): dconf-WARNING **: failed to commit changes to dconf:
  # GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name
  # ca.desrt.dconf was not provided by any .service files
  services.dbus.packages = with pkgs; [ gnome3.dconf ];

  virtualisation.docker.enable = true;
}
