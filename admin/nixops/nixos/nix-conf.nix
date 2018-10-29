{ config, lib, pkgs, ... }:
rec {
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  systemd.tmpfiles.rules = [
    "D! /tmp 1777 root root"
    "d /tmp 1777 root root 10d"
  ];

  zramSwap.enable = true;

  nix.useSandbox = true;
  nix.autoOptimiseStore = true;
  #nix.extraOptions = ''
  #   plugin-files = ${pkgs.nix-plugins.override { nix = config.nix.package; }}/lib/nix/plugins/libnix-extra-builtins.so
  # '';
  nix.binaryCaches = [
    "https://cache.nixos.org"
    "https://r-ryantm.cachix.org"
  ];
  nix.binaryCachePublicKeys = [
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
    "r-ryantm.cachix.org-1:gkUbLkouDAyvBdpBX0JOdIiD2/DP1ldF3Z3Y6Gqcc4c="
  ];

  # Needed by RPi firmware
  nixpkgs.overlays = [ (import ../pkgs-pinned-overlay.nix { system = nixpkgs.system; }) ];
  nixpkgs.config = {pkgs}: (import ~/.config/nixpkgs/config.nix { inherit pkgs; }) // {
    allowUnfree = true;
    #packageOverrides.linuxPackages = boot.kernelPackages;
  };
}
