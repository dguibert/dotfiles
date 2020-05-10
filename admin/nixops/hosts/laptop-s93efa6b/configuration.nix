{ config, pkgs, lib, ... }:
with lib;
rec {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ../common.nix
    ../../users/dguibert
    ../../modules/yubikey-gpg.nix
    ../../modules/distributed-build.nix
    ../../modules/nix-conf.nix
    ../../modules/x11.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "laptop-s93efa6b"; # Define your hostname.
  networking.supplicant.wlp4s0 = {
    configFile.path = "/persist/etc/wpa_supplicant.conf";
    userControlled.group = "network";
    extraConf = ''
      ap_scan=1
      p2p_disabled=1
    '';
    extraCmdArgs = "-u -W";
  };
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  #networking.wireless.userControlled.enable = true;
  #environment.etc."wpa_supplicant.conf".source = "/persist/etc/wpa_supplicant.conf";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  #networking.useDHCP = false;
  #networking.interfaces.enp0s31f6.useDHCP = true;
  #networking.interfaces.wlp4s0.useDHCP = true;
  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
    "" # clear old command
    "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --ignore wlp4s0 --ignore enp0s31f6 --ignore vboxnet0"
  ];

  networking.useNetworkd = lib.mkForce false;
  networking.dhcpcd.enable = false;

  systemd.network.netdevs."40-bond0" = {
    netdevConfig.Name = "bond0";
    netdevConfig.Kind = "bond";
    bondConfig.Mode="active-backup";
    bondConfig.MIIMonitorSec="100s";
    bondConfig.PrimaryReselectPolicy="always";
  };
  systemd.network.networks = {
    "40-bond0" = {
      name = "bond0";
      DHCP = "both";
      networkConfig.BindCarrier = "enp0s31f6 wlp4s0";
    };
  } // listToAttrs (flip map [ "enp0s31f6" "wlp4s0" ] (bi:
    nameValuePair "40-${bi}" {
      name="${bi}";
      DHCP = "no";
      networkConfig.Bond = "bond0";
      networkConfig.IPv6PrivacyExtensions = "kernel";
    }));

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     vim
     pavucontrol
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };

  programs.bash.enableCompletion = true;
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.ports = [22];
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  # https://wiki.archlinux.org/index.php/PulseAudio/Troubleshooting#Laggy_sound
  hardware.pulseaudio.daemon.config.default-fragments = "5";
  hardware.pulseaudio.daemon.config.default-fragment-size-msec = "2";

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "fr";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;
  #services.xserver.desktopManager.pantheon.enable = true;

  # sudo /run/current-system/fine-tune/child-1/bin/switch-to-configuration test
  #- The option definition `nesting.clone' in `flake.nix' no longer has any effect; please remove it.
  #specialisation.«name» = { inheritParentConfig = true; configuration = { ... }; }
  specialisation.work = { inheritParentConfig = true; configuration = {
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

    };
  };

  # https://nixos.org/nixops/manual/#idm140737318329504
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemuOvmfPackage = pkgs.OVMF.override { secureBoot=true; tpmSupport=true; };
  # https://github.com/NixOS/nixpkgs/issues/75878
  systemd.services.libvirtd.environment.EBTABLES_PATH="${pkgs.ebtables}/bin/ebtables-legacy";
  # https://github.com/NixOS/nixpkgs/pull/35214#pullrequestreview-97783209
  security.wrappers.spice-client-glib-usb-acl-helper.source =
    "${pkgs.spice_gtk}/bin/spice-client-glib-usb-acl-helper";

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03"; # Did you read the comment?

  programs.adb.enable = true;

}

