{ config, lib, pkgs, ... }:
rec {
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  systemd.tmpfiles.rules = [
    "D! /tmp 1777 root root"
    "d /tmp 1777 root root 10d"
  ];

  zramSwap.enable = true;
  zramSwap.algorithm = "lzo";

  nix.useSandbox = true; #"relaxed";
  nix.autoOptimiseStore = true; #lib.mkForce false;
  #nix.optimise.automatic=true;
  nix.extraOptions = ''
    keep-outputs = true       # Nice for developers
    keep-derivations = true   # Idem
    extra-sandbox-paths = /opt/intel/licenses=$HOME/nur-packages/secrets?
    experimental-features = nix-command flakes ca-references recursive-nix
  '';
#     plugin-files = ${pkgs.nix-plugins.override { nix = config.nix.package; }}/lib/nix/plugins/libnix-extra-builtins.so
#   '';
  nix.binaryCaches = [
    "https://cache.nixos.org"
    "https://r-ryantm.cachix.org"
    "https://arm.cachix.org"
    "https://dguibert.cachix.org"
  ];
  nix.binaryCachePublicKeys = [
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
    "r-ryantm.cachix.org-1:gkUbLkouDAyvBdpBX0JOdIiD2/DP1ldF3Z3Y6Gqcc4c="
    "arm.cachix.org-1:fGqEJIhp5zM7hxe/Dzt9l9Ene9SY27PUyx3hT9Vvei0="
    "dguibert.cachix.org-1:vb2EHDaV82f6qqfxmapK3AQOPsVfJFO6/g7pbHSEMjY="
  ];
}
