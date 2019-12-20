{ versions ? import ./versions.nix
, nixpkgs ? { outPath = <nixpkgs>; revCount = 123456; shortRev = "gfedcba"; }
, nur_dguibert ? { outPath = <nur_dguibert>; revCount = 123456; shortRev = "gfedcba"; }
, nixos-generators ? { outPath = <nixos-generators>; revCount = 123456; shortRev = "gfedcba"; }
, overlays_ ? []
#, overlays_ ? [ (import "${nur_dguibert}/overlays/local-aloy.nix") ]
, system ? builtins.currentSystem

, pkgs ? import nixpkgs {
    config = import "${nur_dguibert}/config.nix";
    overlays = let
      overlays' = import "${nur_dguibert}/overlays";
    in [
      overlays'.default
      overlays'.aocc
      overlays'.flang
      overlays'.intel-compilers
      #overlays.arm
      overlays'.pgi
      overlays'.local
    ] ++ overlays_;
  }
}:

with pkgs;
with pkgs.lib;
let
  trace = if builtins.getEnv "VERBOSE" == "1" then builtins.trace else (x: y: y);

  mkHost = name: system: config: import <nixpkgs/nixos> {
    inherit system;
    configuration = {
      imports = [
        config
	({...}: {
           networking.hostName = mkDefault name;
	 })
      ];
    };
  };

  mkIso = name: system: config: import <nixpkgs/nixos> {
    inherit system;
    configuration = {
      imports = [
        <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
        config
      ];
    };
  };

  mkHome = system: home_config: confAttr: overlays: (import <home-manager/home-manager/home-manager.nix> {
      pkgs = import <nixpkgs> {
        overlays = [ ];
	config = { };
      };
      confPath = (import home_config { inherit system overlays; }).${confAttr};
      confAttr = "";
      check = true;
      newsReadIdsFile = null;
      }).activationPackage;

  makeNetboot = system: config:
    let
      configEvaled = import <nixpkgs/nixos> {
        inherit system;
        configuration = {
          imports = [
            <nixpkgs/nixos/modules/installer/netboot/netboot.nix>
            config
          ];
	};
      };
      build = configEvaled.config.system.build;
      kernelTarget = configEvaled.pkgs.stdenv.hostPlatform.platform.kernelTarget;
    in
      pkgs.symlinkJoin {
        name = "netboot";
        paths = [
          build.netbootRamdisk
          build.kernel
          build.netbootIpxeScript
        ];
        postBuild = ''
          mkdir -p $out/nix-support
          echo "file ${kernelTarget} ${build.kernel}/${kernelTarget}" >> $out/nix-support/hydra-build-products
          echo "file initrd ${build.netbootRamdisk}/initrd" >> $out/nix-support/hydra-build-products
          echo "file ipxe ${build.netbootIpxeScript}/netboot.ipxe" >> $out/nix-support/hydra-build-products
        '';
        preferLocalBuild = true;
      };


  jobs = {
    nix = pkgs.nix;

    vbox-57nvj72  = (mkHost "vbox-57nvj72"  "x86_64-linux" ./config/vbox-57nvj72/configuration.nix).system;

    titan         = (mkHost "titan"  "x86_64-linux" ./config/titan/configuration.nix).system;
    orsine        = (mkHost "orsine" "x86_64-linux" ./config/orsine/configuration.nix).system;
    rpi31         = (mkHost "rpi31"  "aarch64-linux" ./config/rpi31/configuration.nix).system;
    rpi31_cross   = (mkHost "rpi31"  builtins.currentSystem (./config/rpi31_cross/configuration.nix)).system;
    rpi31_sd      = (mkHost "rpi31"  "aarch64-linux" ./config/rpi31/configuration.nix).config.system.build.sdImage;

    iso = (mkIso "iso" "x86_64-linux" {}).config.system.build.isoImage;

    #dt2-64g_iso = (import "${nixos-generators}/nixos-generate.nix" { inherit nixpkgs;
    #  configuration = ./config/dt2-64g/configuration.nix;
    #  format-config = "${nixos-generators}/formats/iso.nix";
    #}).config.system.build.isoImage;

    #dt2-64g_sd = (mkHost "dt2-64g" "x86_64-linux" ./config/dt2-64g/configuration.nix).config.system.build.sdImage;

    #netboot = makeNetboot "x86_64-linux" ./netboot.nix;
    #netboot_iso = (mkIso "iso" "x86_64-linux" ./netboot.nix).config.system.build.isoImage;

    hm_root   = genAttrs ["x86_64-linux" "aarch64-linux" ] (system: mkHome system ./config/users/root/home.nix "home" []);
    hm_dguibert_nox11 = genAttrs ["x86_64-linux" "aarch64-linux"     ] (system: mkHome system ./config/users/dguibert/home.nix "withoutX11" []);
    hm_dguibert_x11   = genAttrs ["x86_64-linux" /*"aarch64-linux"*/ ] (system: mkHome system ./config/users/dguibert/home.nix "withX11" []);

    hm_dguibert_aloy = mkHome "x86_64-linux" ./config/users/dguibert/home.nix "cluster" [
      (import <nur_dguibert/overlays>).nix-home-nfs-robin-ib-bguibertd
      (import <nur_dguibert/overlays/local-aloy.nix>)
    ];
    hm_dguibert_spartan = mkHome "x86_64-linux" ./config/users/dguibert/home.nix "cluster" [
      (import <nur_dguibert/overlays>).nix-home-nfs-robin-ib-bguibertd
      (import <nur_dguibert/overlays/local-spartan.nix>)
    ];
    hm_dguibert_genji = mkHome "x86_64-linux" ./config/users/dguibert/home.nix "cluster" [
      (import <nur_dguibert/overlays>).nix-home-nfs-robin-ib-bguibertd
      (import <nur_dguibert/overlays/local-genji.nix>)
    ];
    hm_dguibert_manny = mkHome "x86_64-linux" ./config/users/dguibert/home.nix "manny" [
      (import <nur_dguibert/overlays>).nix-home-nfs-bguibertd
    ];
    hm_dguibert_inti = mkHome "aarch64-linux" ./config/users/dguibert/home.nix "inti" [
      (import <nur_dguibert/overlays>).nix-ccc-guibertd
      (import <nur_dguibert/overlays/local-inti.nix>)
    ];
  };
  # https://katyucha.ovh/posts/2018-07-23-nix-container.html
in jobs
