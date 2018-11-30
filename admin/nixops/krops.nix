# https://tech.ingolf-wagner.de/nixos/krops/
let
  versions = import ./config/lib/versions.nix;

  lib_ = import "${versions.krops}/lib";
  pkgs = import "${versions.krops}/pkgs" { };

  source = name: lib_.evalSource [{
    nixpkgs.file = versions.nixpkgs;
    home-manager.file = versions.home-manager;
    #nixpkgs-overlays.file = toString "${versions.nixpkgs-overlays}/overlays";

    config.file = toString ./config;
    modules.file = toString ./modules;
    network.file = toString ./deploy-krops.nix;
    nixos-config.symlink = "config/${name}/configuration.nix";
    secrets.pass = {
      dir  = toString ./secrets;
      name = "${name}";
    };
  }];

  rpi31 = pkgs.krops.writeDeploy "deploy-rpi31" {
    source = source "rpi31";
    target = "root@192.168.1.13:443";
  };

  orsine = pkgs.krops.writeDeploy "deploy-orsine" {
    source = source "orsine";
    target = "root@192.168.1.12:22322";
  };

in {
  rpi31 = rpi31;
  orsine = orsine;
  all = pkgs.krops.writeDeploy "deploy-home-servers"
    (pkgs.lib.concatStringSep "\n" [ rpi31 orsine ]);
}
