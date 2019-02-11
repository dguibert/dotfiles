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

  boot.kernelParams = ["resume=/dev/zvol/icybox1/swap" "console=tty0" "console=ttyS0,115200n8" ];
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

  qemu-user.aarch64 = true;

  services.openssh.enable = true;

  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = [ pkgs.linuxPackages.perf ];
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

  systemd.network.netdevs."40-bond0" = {
    netdevConfig.Name = "bond0";
    netdevConfig.Kind = "bond";
    bondConfig.Mode="active-backup";
    bondConfig.MIIMonitorSec="100s";
    bondConfig.PrimaryReselectPolicy="always";
  };
  systemd.network.networks."40-bond0" = {
    name = "bond0";
    DHCP = "both";
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
  # services.xserver.videoDrivers = [ "nvidia" ];
  #services.xserver.videoDrivers = [ "nvidiaLegacy340" ];
  ## [   13.576513] NVRM: The NVIDIA Quadro FX 550 GPU installed in this system is
  ##                NVRM:  supported through the NVIDIA 304.xx Legacy drivers. Please
  ##                NVRM:  visit http://www.nvidia.com/object/unix.html for more
  ##                NVRM:  information.  The 340.104 NVIDIA driver will ignore
  ##                NVRM:  this GPU.  Continuing probe...
  #hardware.nvidia.modesetting.enable = true;
  services.xserver.videoDrivers = [ "nouveau" /*"nvidiaLegacy304"*/ ];

  hardware.opengl.enable = true;
  hardware.opengl.extraPackages = [ pkgs.vaapiVdpau pkgs.libvdpau-va-gl ];

  hardware.pulseaudio.enable = true;
  environment.systemPackages = [ pkgs.pavucontrol pkgs.ipmitool ];

  # https://nixos.org/nixops/manual/#idm140737318329504
  virtualisation.libvirtd.enable = true;
  #services.nfs.server.enable = true;
  #virtualisation.docker.enable = false;
  networking.firewall.checkReversePath = false;
  systemd.tmpfiles.rules = [ "d /var/lib/libvirt/images 1770 root libvirtd -" ];

  services.disnix.enable = true;
}
