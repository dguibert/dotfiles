{ config, lib, pkgs, outputs, ... }: {
  nixpkgs.localSystem = {
    #gcc.arch = "skylake"; #kabylake
    #gcc.tune = "skylake"; #kabylake
    system = "x86_64-linux";
  };
  imports = [
    (import ./configuration.nix)
    outputs.nixosModules.defaults
  ];
  sops.defaultSopsFile = ./secrets/secrets.yaml;
}
