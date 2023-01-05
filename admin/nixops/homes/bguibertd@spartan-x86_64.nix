{ lib, config, pkgs, inputs, outputs, ... }:
{
  imports = [
    ./dguibert/home.nix
    ./dguibert/emacs.nix
    ./dguibert/custom-profile.nix
  ];
  centralMailHost.enable = false;
  withGui.enable = false;
  withCustomProfile.enable = true;
  withCustomProfile.suffix = "x86_64";

  nixpkgs.overlays = [
    inputs.nur_dguibert.overlays.cluster
    inputs.nur_dguibert.overlays.store-spartan
  ];
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
