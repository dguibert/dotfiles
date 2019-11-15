{ nixpkgs
, nur_dguibert
, home-manager
, ... }@flakes:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    {
      nixpkgs.config = import "${nur_dguibert}/config.nix";
      nixpkgs.overlays = [
        nur_dguibert.overlays.default
      ];
    }
    nixpkgs.nixosModules.notDetected
    (import ./orsine/configuration.nix)
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

