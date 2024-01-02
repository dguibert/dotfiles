{ config, lib, withSystem, inputs, self, ... }:
let
  genHomeManagerConfiguration = import ../lib/gen-home-manager-configuration.nix { inherit lib; };
in
{
  imports = [
    (genHomeManagerConfiguration "x86_64-linux" "hm-aarch64-cross-check")
  ];
  
  modules.homes."hm-aarch64-cross-check-cross-system" = "aarch64-multiplatform";
  modules.homes."hm-aarch64-cross-check" = [
    ({ config, pkgs, lib, ... }: {
      imports = [
        #../modules/home-manager/dguibert.nix
        ../modules/home-manager/dguibert/git.nix
        ../modules/home-manager/dguibert/custom-profile.nix
      ];
      manual.manpages.enable = false;
      #centralMailHost.enable = false;
      #withGui.enable = false;
      #withCustomProfile.enable = true;
      #withCustomProfile.suffix = "aarch64";
      #withEmacs.enable = false;

      home.username = "bguibertd";
      home.homeDirectory = "/home_nfs/bguibertd";
      home.stateVersion = "22.11";

      programs.git.package = lib.mkForce pkgs.gitMinimal;
      home.sessionPath = [
        "${pkgs.nix}/bin"
      ];

      home.packages = with pkgs; [
        bashInteractive
      ];
    })
  ];

  perSystem = { config, self', inputs', pkgs, system, ... }: {
    checks = {
      hm-aarch64-cross-check = self.homeConfigurations.hm-aarch64-cross-check.activationPackage;
    };
  };
}
