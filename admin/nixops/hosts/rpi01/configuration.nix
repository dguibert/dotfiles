{ config, pkgs, lib, ... }:

with lib;

rec {
  networking.hostName = "rpi01";

  services.openssh.enable = true;

  nixpkgs.overlays = [
    (self: super: {
      ## Restrict drivers built by mesa to just the ones we need This
      ## reduces the install size a bit.
      #mesa = (super.mesa.override {
      #  vulkanDrivers = [];
      #  driDrivers = [];
      #  galliumDrivers = ["vc4" "swrast"];
      #  enableRadv = false;
      #  withValgrind = false;
      #  #enableOSMesa = false;
      #  #enableGalliumNine = false;
      #}).overrideAttrs (o: {
      #  mesonFlags = (o.mesonFlags or []) ++ ["-Dglx=disabled"];
      #});

      #libcec = super.libcec.override { inherit (super) libraspberrypi; };
    })
  ];

  boot.loader.grub.enable = false;
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 0;
  boot.loader.raspberryPi.uboot.enable = true;
  boot.loader.raspberryPi.uboot.configurationLimit = 10;
  boot.loader.raspberryPi.firmwareConfig = ''
    disable_splash=1
  '';
  #  dtparam=audio=on
  #  gpu_mem=${toString gpu-mem}
  #  dtoverlay=${gpu-overlay}
  #'';


  boot.consoleLogLevel = lib.mkDefault 7;
  boot.kernelPackages = pkgs.linuxPackages_rpi1;

  sdImage = {
    firmwareSize = 512;
    populateFirmwareCommands =
      let
        configTxt = pkgs.writeText "config.txt" ''
          # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
          # when attempting to show low-voltage or overtemperature warnings.
          avoid_warnings=1

          [pi0]
          kernel=u-boot-rpi0.bin

          [pi1]
          kernel=u-boot-rpi1.bin
        '';
      in
      ''
        (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)
        cp ${pkgs.ubootRaspberryPiZero}/u-boot.bin firmware/u-boot-rpi0.bin
        cp ${pkgs.ubootRaspberryPi}/u-boot.bin firmware/u-boot-rpi1.bin
        cp ${configTxt} firmware/config.txt
      '';
    populateRootCommands = ''
    '';
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
  };

}
