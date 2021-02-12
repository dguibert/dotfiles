# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
#  imports =
#    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
#    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "acpi_call" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  networking.hostId="8425e349"; # - ZFS requires networking.hostId to be set
  boot.kernelParams = [ "acpi_backlight=vendor" "resume=LABEL=nvme-swap" "elevator=none" "i915.enable_fbc=0" ];
  swapDevices = [ { label = "nvme-swap"; } ];

  fileSystems."/" = { device = "rt580/local/root"; fsType = "zfs"; };
  fileSystems."/boot" = { device = "/dev/disk/by-uuid/FE98-E8BD"; fsType = "vfat"; };
  fileSystems."/nix" = { device = "rt580/local/nix"; fsType = "zfs"; neededForBoot=true; };
  fileSystems."/home" = { device = "rt580/safe/home"; fsType = "zfs"; };
  fileSystems."/root" = { device = "rt580/safe/home/root"; fsType = "zfs"; };
  fileSystems."/persist" = { device = "rt580/safe/persist"; fsType = "zfs"; neededForBoot=true; };

  # https://grahamc.com/blog/erase-your-darlings
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rt580/local/root@blank
  '';

  #boot.kernelPackages = pkgs.linuxPackages_5_10;
  # https://lists.ubuntu.com/archives/kernel-team/2020-November/114986.html
  boot.kernelPackages = pkgs.linuxPackages_testing;
  #boot.zfs.enableUnstable = true;

  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "monthly";
  services.zfs.trim.enable = true;
  # https://grahamc.com/blog/nixos-on-zfs
  # rt580/
  # ├── local
  # │   ├── nix
  # │   └── root
  # └── safe
  #     └── home
  #         ├── dguibert
  #         └── root
  services.sanoid = {
    enable = true;
    interval = "*:00,15,30,45"; #every 15minutes
    templates.user = {
      frequently = 8;
      hourly = 24;
      daily = 7;
      monthly = 3;
      yearly = 0;

      autosnap = true;
    };
    templates.root = {
      frequently = 8;
      hourly = 4;
      daily = 2;
      monthly = 2;
      yearly = 0;

      autosnap = true;
    };
    datasets."rt580/safe".useTemplate = [ "user" ];
    datasets."rt580/safe".recursive = true;
    datasets."rt580/local/root".useTemplate = [ "root" ];
    datasets."rt580/local/root".recursive = true;

    extraArgs = [ "--verbose" ];
  };

  nix.maxJobs = lib.mkDefault 8;

  services.xserver.libinput.enable = lib.mkDefault true;
  hardware.trackpoint.enable = lib.mkDefault true;
  hardware.trackpoint.emulateWheel = lib.mkDefault config.hardware.trackpoint.enable;

  # Disable governor set in hardware-configuration.nix,
  # required when services.tlp.enable is true:
  powerManagement.cpuFreqGovernor =
    lib.mkIf config.services.tlp.enable (lib.mkForce null);

  services.tlp.enable = lib.mkDefault true;
}
