{
  description = "A nixpkgs with overriden stdenv";

  inputs.nix.url = "github:NixOS/nix";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nix-custom-store.inputs.nix.follows = "nix";
  inputs.nix-custom-store.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix-custom-store.url = "github:dguibert/nix-custom-store";

  outputs = { self, nixpkgs, nix-custom-store }:
    let
      nixpkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [
          nix-custom-store.overlays.default
          self.overlays.default
        ];
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

        coreutils = dontCheck prev.coreutils;
        bind = dontCheck prev.bind;
        dbus = dontCheck prev.dbus;
        libffi = dontCheck prev.libffi;
        libuv = dontCheck prev.libuv;
        p11-kit = dontCheck prev.p11-kit;
      };

      legacyPackages.x86_64-linux = nixpkgsFor "x86_64-linux";
    };
}
