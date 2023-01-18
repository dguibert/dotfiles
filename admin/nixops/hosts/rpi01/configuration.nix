{ config, pkgs, lib, inputs, outputs, ... }:

with lib;

rec {
  imports = [
    (import "${inputs.nixpkgs.inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix")
  ];
  #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
  #nixpkgs.localSystem.system = "x86_64-linux";
  #nixpkgs.crossSystem = { config = "armv6l-unknown-linux-gnueabihf"; };
  #nixpkgs.localSystem.system = "armv6l-linux";
  nixpkgs.overlays = [
    (final: prev: {
      # don't build qt5
      # enabledFlavors ? [ "curses" "tty" "gtk2" "qt" "gnome3" "emacs" ]
      pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
      git = prev.git.override { perlSupport = false; };
    })
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

  networking.hostName = "rpi01";

  services.openssh.enable = true;

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
