{ self
, nixpkgs
, nur_dguibert
, home-manager
, ... }@flakes:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    #self.nixosModules.systemTarget
    {
  #    mobile.system.system = "aarch64-linux";
  # see commit c6f7d4367894047592cc412740f0c1f5b2ca2b59
  #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
  nixpkgs.localSystem.system = "aarch64-linux";
  #assertions = lib.singleton {
  #  assertion = pkgs.stdenv.system == "aarch64-linux";
  #  message = "rpi31-configuration.nix can be only built natively on Aarch64 / ARM64; " +
  #    "it cannot be cross compiled";
  #};
      nixpkgs.config = import "${nur_dguibert}/config.nix";
      nixpkgs.overlays = [
        nur_dguibert.overlays.default
      ];
    }
    nixpkgs.nixosModules.notDetected
    (import "${nixpkgs}/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix")
    (import "${nixpkgs}/nixos/modules/profiles/minimal.nix")
    (import ./rpi31/configuration.nix)
    #(import "${home-manager}/nixos")
    ## file 'nixpkgs/nixos/modules/misc/assertions.nix' was not found in the Nix search path (add it using $NIX_PATH or -I), at /nix/store/0kj2qmx1g7y1y42icd9aqk9rzc3dvfyd-source/modules/modules.nix:144:17
    #({ pkgs, config, lib, ... }: {
    #  home-manager.users.dguibert = (import ./users/dguibert/home.nix { system="x86_64-linux"; }).withX11 { inherit pkgs lib config; };
    #})
    ({config, lib, pkgs, ...}: {
      environment.shellInit = ''
         export NIX_PATH=nixpkgs=${nixpkgs}:nur_dguibert=${nur_dguibert}
      '';

      nix.autoOptimiseStore = true;
      nix.extraOptions = ''
        plugin-files = ${pkgs.nix-plugins.override { nix = config.nix.package; }}/lib/nix/plugins/libnix-extra-builtins.so
      '';
    })
  ];
}

