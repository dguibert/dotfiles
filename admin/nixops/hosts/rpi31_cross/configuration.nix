{ config, pkgs, lib, ... }:

{
  imports = [
    ../rpi31/configuration.nix
  ];
  nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
  nixpkgs.localSystem.system = builtins.currentSystem;
}

