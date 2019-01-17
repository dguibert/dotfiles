{
}:

with (import <nixpkgs> {});
with (import <nixpkgs/lib>);
let
  trace = if builtins.getEnv "VERBOSE" == "1" then builtins.trace else (x: y: y);

  mkHost = name: system: config: import <nixpkgs/nixos> { 
    inherit system;
    configuration = {
      imports = [
        config
	({...}: {
           networking.hostName = name;
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

  mkHome = system: noX11: (import <home-manager/home-manager/home-manager.nix> {
      pkgs = import <nixpkgs> {
        overlays = [ (import <config/pkgs-pinned-overlay.nix> { }) ];
        config = {pkgs}: (import <config/nixpkgs/config.nix> { inherit pkgs; }) // {
        ##  #packageOverrides.linuxPackages = boot.kernelPackages;
        };
      };
      confPath = import <config/nixpkgs/home.nix> { noXlibs = false; };
      confAttr = "";
      check = true;
      newsReadIdsFile = null;
      }).activationPackage;

  jobs = recurseIntoAttrs {
    vbox-57nvj72  = (mkHost "vbox-57nvj72"  "x86_64-linux" <config/vbox-57nvj72/configuration.nix>).system;

    titan         = (mkHost "titan"  "x86_64-linux" <config/titan/configuration.nix>).system;
    orsine        = (mkHost "orsine" "x86_64-linux" <config/orsine/configuration.nix>).system;
    rpi31         = (mkHost "rpi31"  "aarch64-linux" <config/rpi31/configuration.nix>).system;

    iso = (mkIso "iso" "x86_64-linux" {}).config.system.build.isoImage;

    hm_dguibert_nox11 = genAttrs ["x86_64-linux" "aarch64-linux" ] (system: mkHome system false);
    hm_dguibert_x11   = genAttrs ["x86_64-linux" /*"aarch64-linux"*/ ] (system: mkHome system true);
  };
  # https://katyucha.ovh/posts/2018-07-23-nix-container.html
in jobs
