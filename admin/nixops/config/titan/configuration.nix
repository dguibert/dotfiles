# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

rec {
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
      <config/common.nix>
      <config/users/dguibert>
      <modules/yubikey-gpg.nix>
      <modules/distributed-build.nix>
      <modules/nix-conf.nix>
      <modules/x11.nix>
      <modules/zfs.nix>
      (import <nur_dguibert/modules>).qemu-user
    ];

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "isci" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/"         = { device = "icybox1/root/nixos"; fsType = "zfs"; };
  fileSystems."/home"     = { device = "icybox1/home"; fsType = "zfs"; };
  fileSystems."/boot/efi" = { label = "EFI1"; fsType = "vfat"; };
  fileSystems."/tmp"      = { device="tmpfs"; fsType="tmpfs"; options= [ "defaults" "noatime" "mode=1777" "size=15G" ]; neededForBoot=true; };

  boot.kernelParams = ["resume=/dev/zvol/icybox1/swap" "console=tty0" "console=ttyS2,115200n8" ];
  swapDevices = [ { device="/dev/zvol/icybox1/swap"; } ];

  nix.maxJobs = lib.mkDefault 4;
  nix.buildCores = lib.mkDefault 16;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";

  networking.hostId="8425e349";
  networking.hostName = "titan";

  qemu-user.aarch64 = true;

  services.openssh.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_5_2;
  boot.extraModulePackages = [ pkgs.linuxPackages.perf ];
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

  networking.useNetworkd = lib.mkForce false;
  networking.dhcpcd.enable = false;
  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
    "" # clear old command
    "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --ignore eno1 --ignore eno2"
  ];
  systemd.network.netdevs."40-bond0" = {
    netdevConfig.Name = "bond0";
    netdevConfig.Kind = "bond";
    #[Bond]
    #Mode=active-backup
    #PrimaryReselectPolicy=always
    #PrimarySlave=enp3s0
    #TransmitHashPolicy=layer3+4
    #MIIMonitorSec=1s
    #LACPTransmitRate=fast

    bondConfig.Mode="active-backup";
    #bondConfig.PrimarySlave="eno1";
    bondConfig.MIIMonitorSec="100s";
    bondConfig.PrimaryReselectPolicy="always";
  };
  systemd.network.networks."40-bond0" = {
    name = "bond0";
    DHCP = "yes";
    networkConfig.BindCarrier = "eno1 eno2";
  };
  systemd.network.networks."40-eno1" = {
    name = "eno1";
    DHCP = "none";
    networkConfig.Bond = "bond0";
    networkConfig.IPv6PrivacyExtensions = "kernel";
  };
  systemd.network.networks."40-eno2" = {
    name = "eno2";
    DHCP = "none";
    networkConfig.Bond = "bond0";
    networkConfig.IPv6PrivacyExtensions = "kernel";
  };
  # rpi31
  networking.wireguard.interfaces.rpi31 = {
    ips = [
      "10.147.27.24/32"
      "fe80::216:3eff:fe3f:017c/64"
    ];
    listenPort = 500;
    allowedIPsAsRoutes=false;
    privateKeyFile = toString <secrets/wireguard_key>;
    peers = [
      { allowedIPs = [ "0.0.0.0/0" "ff02::/16" "::/0" ];
        publicKey  = "wBBjx9LCPf4CQ07FKf6oR8S1+BoIBimu1amKbS8LWWo=";
        endpoint   = "orsin.freeboxos.fr:503";
        persistentKeepalive = 25;
      }
    ];
  };
  # orsine
  networking.wireguard.interfaces.orsine = {
    ips = [
      "10.147.27.24/32"
      "fe80::216:3eff:fe58:2eae/64"
    ];
    listenPort = 501;
    allowedIPsAsRoutes=false;
    privateKeyFile = toString <secrets/wireguard_key>;
    peers = [
      { allowedIPs = [ "0.0.0.0/0" "ff02::/16" "::/0" ];
        publicKey  = "Z8yyrih3/vINo6XlEi4dC5i3wJCKjmmJM9aBr4kfZ1k=";
	endpoint   = "192.168.1.32:503";
	persistentKeepalive = 25;
      }
    ];
  };
  # vbox-54nj72
  networking.wireguard.interfaces.vbox-54nvj72 = {
    ips = [
      "10.147.27.24/32"
      "fe80::216:3eff:fe16:d620/64"
    ];
    listenPort = 502;
    allowedIPsAsRoutes=false;
    privateKeyFile = toString <secrets/wireguard_key>;
    peers = [
      { allowedIPs = [ "0.0.0.0/0" "ff02::/16" "::/0" ];
        publicKey  = "rbYanMKQBY/dteQYQsg807neESjgMP/oo+dkDsC5PWU=";
	#endpoint   = "orsin.freeboxos.fr:503";
	#persistentKeepalive = 25;
      }
    ];
  };
  ## titan
  #networking.wireguard.interfaces.titan = {
  #  ips = [
  #    "10.147.27.24/32"
  #    "fe80::216:3eff:fe06:e0b6/64"
  #  ];
  #  listenPort = 503;
  #  allowedIPsAsRoutes=false;
  #  privateKeyFile = toString <secrets/wireguard_key>;
  #};
  networking.firewall.allowedUDPPorts = [ 9993 500 501 502 503 6696 ];
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = "1";
    "net.ipv6.conf.all.forwarding"="1";
  };
  services.babeld.enable = true;
  services.babeld.interfaceDefaults = {
    type = "tunnel";
    "split-horizon" = true;
  };
  services.babeld.extraConfig = ''
    interface orsine
    interface titan
    interface rpi31
    interface vbox-54nvj72
    # mesh IPv4
    redistribute local ip 10.147.27.0/24 metric 128
    redistribute ip 10.147.27.0/24 ge 13 metric 128
    ## refuse anything else not explicitely allowed
    redistribute local deny
    redistribute deny
  '';


  # services.xserver.videoDrivers = [ "nvidia" ];
  #services.xserver.videoDrivers = [ "nvidiaLegacy340" ];
  ## [   13.576513] NVRM: The NVIDIA Quadro FX 550 GPU installed in this system is
  ##                NVRM:  supported through the NVIDIA 304.xx Legacy drivers. Please
  ##                NVRM:  visit http://www.nvidia.com/object/unix.html for more
  ##                NVRM:  information.  The 340.104 NVIDIA driver will ignore
  ##                NVRM:  this GPU.  Continuing probe...
  hardware.nvidia.modesetting.enable = true;
  services.xserver.videoDrivers = [ "nvidia" /*"nouveau"*/ /*"nvidiaLegacy304"*/ /*"displaylink"*/ ];
  #nixpkgs.config.xorg.abiCompat = "1.18";

  hardware.opengl.enable = true;
  hardware.opengl.extraPackages = [ pkgs.vaapiVdpau pkgs.libvdpau-va-gl ];

  hardware.pulseaudio.enable = true;
  environment.systemPackages = [ pkgs.pavucontrol pkgs.ipmitool pkgs.ntfs3g ];

  # https://nixos.org/nixops/manual/#idm140737318329504
  virtualisation.libvirtd.enable = true;
  #virtualisation.anbox.enable = true;
  #services.nfs.server.enable = true;
  virtualisation.docker.enable = true;
  networking.firewall.checkReversePath = false;
  systemd.tmpfiles.rules = [ "d /var/lib/libvirt/images 1770 root libvirtd -" ];

  services.disnix.enable = true;

  programs.adb.enable = true;

  services.jellyfin.enable = true;
  networking.firewall.interfaces."bond0".allowedTCPPorts = [ 8096 /*http*/ 8920 /*https*/ ];

  # https://nixos.org/nixos/manual/index.html#sec-container-networking
  networking.nat.enable = true;
  networking.nat.internalInterfaces = ["ve-+"];
  networking.nat.externalInterface = "bond0";

  services.hydra = {
    enable = true;
    hydraURL = "http://localhost:3000";
    notificationSender = "hydra@orsin.freeboxos.fr";
    port = 3000;
    extraConfig = ''
      store_uri = file:///var/lib/hydra/cache?secret-key=/etc/nix/hydra.orsin.freeboxos.fr-1/secret
      #binary_cache_secret_key_file = /etc/nix/hydra.orsin.freeboxos.fr-1/secret
    '';
    buildMachinesFiles = [ /*"/etc/nix/machines"*/ ];
  };
  nix.buildMachines = [
    {
      hostName = "localhost";
      systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      maxJobs = 16;
      # for building VirtualBox VMs as build artifacts, you might need other
      # features depending on what you are doing
      supportedFeatures = [ "big-parallel" "kvm" ];
    }
  ];

  services.postgresql = {
    package = pkgs.postgresql94;
    dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
  };

  systemd.services.hydra-manual-setup = {
    description = "Create Admin User for Hydra";
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    wantedBy = [ "multi-user.target" ];
    requires = [ "hydra-init.service" ];
    after = [ "hydra-init.service" ];
    environment = config.systemd.services.hydra-init.environment;
    script = ''
      if [ ! -e ~hydra/.setup-is-complete ]; then
        # create admin user
        /run/current-system/sw/bin/hydra-create-user dguibert --full-name 'David G. User' --email-address 'dguibert@orsin.freeboxos.fr' --password foobar --role admin
        # create signing keys
        /run/current-system/sw/bin/install -d -m 551 /etc/nix/hydra.orsin.freeboxos.fr-1
        /run/current-system/sw/bin/nix-store --generate-binary-cache-key hydra.orsin.freeboxos.fr-1 /etc/nix/hydra.orsin.freeboxos.fr-1/secret /etc/nix/hydra.orsin.freeboxos.fr-1/public
        /run/current-system/sw/bin/chown -R hydra:hydra /etc/nix/hydra.orsin.freeboxos.fr-1
        /run/current-system/sw/bin/chmod 440 /etc/nix/hydra.orsin.freeboxos.fr-1/secret
        /run/current-system/sw/bin/chmod 444 /etc/nix/hydra.orsin.freeboxos.fr-1/public
        # create cache (https://qfpl.io/posts/nix/starting-simple-hydra/)
        /run/current-system/sw/bin/install -d -m 755 /var/lib/hydra/cache
        /run/current-system/sw/bin/chown -R hydra-queue-runner:hydra /var/lib/hydra/cache
        # done
        touch ~hydra/.setup-is-complete
      fi
    '';
  };

}
