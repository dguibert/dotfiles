{ config, lib, pkgs, ... }:
rec {
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  systemd.tmpfiles.rules = [
    "D! /tmp 1777 root root"
    "d /tmp 1777 root root 10d"
  ];

  zramSwap.enable = true;

  # FIXME
  # Checking that Nix can read nix.conf...
  # error: could not dynamically open plugin file '/nix/store/3s0msjb7l1m0xff6j0lvg6ycwvy43b5g-nix-plugins-5.0.0/lib/nix/plugins/libnix-extra-builtins.so': /nix/store/3s0msjb7l1m0xff6j0lvg6ycwvy43b5g-nix-plugins-5.0.0/lib/nix/plugins/libnix-extra-builtins.so: undefined symbol: _Z18GC_throw_bad_allocv
  #nix.checkConfig = false;

  nix.useSandbox = true;
  nix.extraOptions = ''
    auto-optimise-store = true
    #plugin-files = ${pkgs.nix-plugins.override { nix = config.nix.package; }}/lib/nix/plugins/libnix-extra-builtins.so
  '';
  nix.binaryCachePublicKeys = [
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
  ];

  # Needed by RPi firmware
  nixpkgs.overlays = [ (import ../pkgs-pinned-overlay.nix { system = nixpkgs.system; }) ];
  nixpkgs.config = {pkgs}: (import ~/.config/nixpkgs/config.nix { inherit pkgs; }) // {
    allowUnfree = true;
    #packageOverrides.linuxPackages = boot.kernelPackages;
  };
}
