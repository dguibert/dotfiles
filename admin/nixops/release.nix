{ versions ? import ./versions.nix
, nixpkgs ? { outPath = versions.nixpkgs; revCount = 123456; shortRev = "gfedcba"; }
, nur_dguibert ? { outPath = versions.nur_dguibert; revCount = 123456; shortRev = "gfedcba"; }
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

  jobs = recurseIntoAttrs {
    nix = pkgs.nix;

    vbox-57nvj72  = (mkHost "vbox-57nvj72"  "x86_64-linux" <config/vbox-57nvj72/configuration.nix>).system;

    titan         = (mkHost "titan"  "x86_64-linux" <config/titan/configuration.nix>).system;
    orsine        = (mkHost "orsine" "x86_64-linux" <config/orsine/configuration.nix>).system;
    rpi31         = (mkHost "rpi31"  "aarch64-linux" <config/rpi31/configuration.nix>).system;
    #rpi31         = (mkHost "rpi31"  builtins.currentSystem <config/rpi31/configuration.nix>).system;
    rpi31_sd      = (mkHost "rpi31"  "aarch64-linux" <config/rpi31/configuration.nix>).config.system.build.sdImage;

    iso = (mkIso "iso" "x86_64-linux" {}).config.system.build.isoImage;

    hm_root   = recurseIntoAttrs (genAttrs ["x86_64-linux" "aarch64-linux" ] (system: mkHome system <config/users/root/home.nix> "home" []));
    hm_dguibert_nox11 = recurseIntoAttrs (genAttrs ["x86_64-linux" "aarch64-linux"     ] (system: mkHome system <config/users/dguibert/home.nix> "withoutX11" []));
    hm_dguibert_x11   = recurseIntoAttrs (genAttrs ["x86_64-linux" /*"aarch64-linux"*/ ] (system: mkHome system <config/users/dguibert/home.nix> "withX11" []));

    hm_dguibert_aloy = mkHome "x86_64-linux" <config/users/dguibert/home.nix> "cluster" [
      (import <nur_dguibert/overlays>).nix-home-nfs-robin-ib-bguibertd
      (import <nur_dguibert/overlays/local-aloy.nix>)
    ];
    hm_dguibert_genji = mkHome "x86_64-linux" <config/users/dguibert/home.nix> "cluster" [
      (import <nur_dguibert/overlays>).nix-home-nfs-robin-ib-bguibertd
      (import <nur_dguibert/overlays/local-genji.nix>)
    ];
    hm_dguibert_manny = mkHome "x86_64-linux" <config/users/dguibert/home.nix> "manny" [
      (import <nur_dguibert/overlays>).nix-home-nfs-bguibertd
    ];
    hm_dguibert_inti = mkHome "aarch64-linux" <config/users/dguibert/home.nix> "inti" [
      (import <nur_dguibert/overlays>).nix-ccc-guibertd
      (import <nur_dguibert/overlays/local-inti.nix>)
    ];
  };
  # https://katyucha.ovh/posts/2018-07-23-nix-container.html
in jobs
