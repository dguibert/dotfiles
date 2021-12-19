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
    #extra-sandbox-paths = /opt/intel/licenses=/home/dguibert/nur-packages/secrets?
    experimental-features = nix-command flakes ca-derivations recursive-nix
  '';
    #plugin-files = ${(pkgs.nix-plugins.override { nix = config.nix.package; }).overrideAttrs (o: {
    #      buildInputs = o.buildInputs ++ [ pkgs.boehmgc pkgs.nlohmann_json ];
    #      patches = (o.patches or []) ++ [
    #        ./0001-compile-with-new-PrimOp-struct.patch
    #        ./0002-avoid-toJSON-template.patch
    #        ./0003-value-mkPrimOp.patch
    #        ./0004-mkStringNoCopy-mkString.patch
    #      ];
    #      })}/lib/nix/plugins/libnix-extra-builtins.so
  nix.binaryCaches = [
    "https://cache.nixos.org"
    "https://r-ryantm.cachix.org"
    "https://arm.cachix.org"
    #"https://cache.ngi0.nixos.org/"
    #"https://nixos-rocm.cachix.org"
  ];
  nix.binaryCachePublicKeys = [
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
    "r-ryantm.cachix.org-1:gkUbLkouDAyvBdpBX0JOdIiD2/DP1ldF3Z3Y6Gqcc4c="
    "arm.cachix.org-1:5BZ2kjoL1q6nWhlnrbAl+G7ThY7+HaBRD9PZzqZkbnM="
    #"cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
    # nixos-rocm.cachix.org-1:VEpsf7pRIijjd8csKjFNBGzkBqOmw8H9PRmgAq14LnE=
  ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
