{
  description = "A nixpkgs with overriden stdenv";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      nixpkgsFor = system: import (nixpkgs.inputs.nixpkgs or nixpkgs) {
        inherit system;
        overlays =
          (nixpkgs.legacyPackages.${system}.overlays or [ ])
          ++ [
            self.overlays.default
          ]
        ;
        config.allowUnfree = true;
        config.allowUnsupportedSystem = true;
        config.replaceStdenv = import ./stdenv.nix;
      };

      dontCheck = pkg: pkg.overrideAttrs (o: {
        doCheck = false;
        doInstallCheck = false;
      });
    in
    {
      lib = nixpkgs.lib;

      overlays.default = final: prev: {
        nss_sss = prev.callPackage ./pkgs/sssd/nss-client.nix { };

        bind = dontCheck prev.bind;
        coreutils = dontCheck prev.coreutils;
        dbus = dontCheck prev.dbus;
        libffi = dontCheck prev.libffi;
        libuv = dontCheck prev.libuv;
        nix = dontCheck prev.nix; # build-remote-input-addressed.sh... [FAIL]
        nixos-option = prev.nixos-option.override {
          nix = dontCheck prev.nixVersions.nix_2_18;
        };
        p11-kit = dontCheck prev.p11-kit;
      };

      legacyPackages.x86_64-linux = nixpkgsFor "x86_64-linux";
    };
}
