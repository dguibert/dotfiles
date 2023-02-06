{ config, lib, pkgs, inputs, outputs, ... }: {
  #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
  #nixpkgs.localSystem.system = "x86_64-linux";
  nixpkgs.localSystem.system = "aarch64-linux";
  imports = [
    (import "${inputs.nixpkgs.inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
    (import ./configuration.nix)
    outputs.nixosModules.defaults
  ];
  boot.kernelPackages = pkgs.linuxPackages_5_10;
  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "uas" "usb_storage" ];
  boot.loader.raspberryPi.firmwareConfig = "dtparam=sd_poll_once=on";
  #fileSystems."/".options = [ "defaults" "discard" ];
  services.fstrim.enable = true;

  ##boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.generic-extlinux-compatible.configurationLimit = 10;
  #boot.loader.raspberryPi.uboot.enable = false;
  #boot.loader.raspberryPi.enable = true;
  #boot.loader.raspberryPi.version = 4;

  nixpkgs.overlays = [
    (final: prev: {
      # don't build qt5
      # enabledFlavors ? [ "curses" "tty" "gtk2" "qt" "gnome3" "emacs" ]
      pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
    })
    (self: super: lib.optionalAttrs (super.stdenv.hostPlatform != super.stdenv.buildPlatform) {
      # Restrict drivers built by mesa to just the ones we need This
      # reduces the install size a bit.
      mesa = (super.mesa.override {
        vulkanDrivers = [ ];
        driDrivers = [ ];
        galliumDrivers = [ "vc4" "swrast" ];
        enableRadv = false;
        withValgrind = false;
        enableOSMesa = false;
        enableGalliumNine = false;
      }).overrideAttrs (o: {
        mesonFlags = (o.mesonFlags or [ ]) ++ [ "-Dglx=disabled" ];
      });

      libcec = super.libcec.override { inherit (super) libraspberrypi; };

      kodiPlain = (super.kodiPlain.override {
        vdpauSupport = false;
        libva = null;
        raspberryPiSupport = true;
      });
    })

  ];

  sdImage.compressImage = false;
  documentation.nixos.enable = false;

  hardware.opengl = {
    enable = true;
    setLdLibraryPath = true;
    package = pkgs.mesa.drivers;
  };
  programs.gnupg.agent.pinentryFlavor = lib.mkForce "curses";

  sops.defaultSopsFile = ./secrets/secrets.yaml;
}
