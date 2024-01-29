{ lib, config, pkgs, inputs, outputs, ... }:
{
  imports = [
    ./dguibert/home.nix
    ./dguibert/custom-profile.nix
  ];
  centralMailHost.enable = false;
  withGui.enable = false;
  withCustomProfile.enable = true;
  withCustomProfile.suffix = "x86_64";
  withEmacs.enable = true;

  home.username = "bguibertd";
  home.homeDirectory = "/home_nfs/bguibertd";
  home.stateVersion = "22.11";

  home.sessionPath = [
    "${pkgs.nix}/bin"
  ];

  home.packages = with pkgs; [
    xpra
    bashInteractive

    datalad
    git-annex
  ];

}
