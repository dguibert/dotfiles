{ config, pkgs, lib, ... }:

with lib;

rec {
  networking.hostName = "rpi01";

  services.openssh.enable = true;

  nixpkgs.overlays = [(self: super: {
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
  })];
}
